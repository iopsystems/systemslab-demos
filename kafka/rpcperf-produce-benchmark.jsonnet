local systemslab = import 'systemslab.libsonnet';
local bash = systemslab.bash;
local upload_artifact = systemslab.upload_artifact;

function(kafka="~/kafka", rpc_perf="~/bin/rpc-perf", kafka_host="", client_host="")  
  {
    name : "RpcPerf_Kafka_Produce_Benchmark",
    jobs: {
      kafka_server: {
        host: {
          tags: if kafka_host == "" then [] else [kafka_host],
        },
        steps: [        
          systemslab.write_file('zookeeper.properties', importstr 'zookeeper.properties'),
          systemslab.write_file('server.properties', importstr 'server.properties'),
          bash(
            |||
              echo "Start Zookeeper"
              KAFKA_DIR=%s
              $KAFKA_DIR/bin/zookeeper-server-start.sh zookeeper.properties > zookeeper.log 2>&1 &
              echo $! > ./zookeeper.pid
              sleep 3
              echo "Start Kafka Broker"
              $KAFKA_DIR/bin/kafka-server-start.sh server.properties > kafka.log 2>&1 &
              echo $! > ./kafka.pid
            ||| % kafka, background=true),        
          bash(
            |||
              sleep 10;
              %s/bin/kafka-cluster.sh  cluster-id  --bootstrap-server localhost:9092       
            ||| % kafka
          ),
          systemslab.barrier('kafka-start'),
          // waiting for the client to finish
          systemslab.barrier('kafka-finish'),
          bash(
            |||
              echo "Terminate Zookeeper `cat ./zookeeper.pid`"
              cat ./zookeeper.pid | xargs kill -9
              echo "Terminate Kafka `cat ./kafka.pid`"
              cat ./kafka.pid | xargs kill -9
            |||
          ),
        ],
      },
      rpcperf_client: {
        host: {
          tags: if client_host == "" then [] else [client_host]
        },
        steps: [ 
          systemslab.write_file('rpcperf-kafka_template.toml', importstr 'rpcperf-kafka.toml'),
          systemslab.barrier('kafka-start'),
          bash(
            |||
              touch rpcperf_output.txt              
              RPC_PERF=%s
              for RPS in $(seq 10000 10000 10000); do
                DURATION_S=70                
                DURATION_MS=$((DURATION_S * 1000))
                MAX_MESSAGES=$((RPS * DURATION_S))
                cp rpcperf-kafka_template.toml rpcperf-kafka.toml
                sed -ie "s/KAFKA_SERVER_ADDR/$KAFKA_SERVER_ADDR/g" rpcperf-kafka.toml
                sed -ie "s/RPS/$RPS/g" rpcperf-kafka.toml
                sed -ie "s/DURATION_S/$DURATION_S/g" rpcperf-kafka.toml                
                echo "==================" >> rpcperf_output.txt
                $RPC_PERF rpcperf-kafka.toml | tee -a rpcperf_output.txt                
              done
            ||| % rpc_perf),
          systemslab.upload_artifact('rpcperf_output.txt'),
          systemslab.barrier('kafka-finish'),
        ]
      }
    },
  }