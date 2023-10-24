local systemslab = import 'systemslab.libsonnet';
local bash = systemslab.bash;
local upload_artifact = systemslab.upload_artifact;

function(kafka="~/kafka", kafka_host="", client_host="")  
  {
    name : "Trogdor_Kafka_Produce_Benchmark",
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
      trogdor_client: {
        host: {
          tags: if client_host == "" then [] else [client_host]
        },
        steps: [          
          systemslab.write_file('trogdor.conf', importstr 'trogdor.conf'),
          systemslab.write_file('simple_produce_bench_template.json', importstr 'simple_produce_bench.json'),
          systemslab.barrier('kafka-start'),
          bash(
            |||
              touch trogdor_output.txt              
              KAFKA_DIR=%s
              for RPS in $(seq 10000 10000 10000); do
                DURATION_S=70                
                DURATION_MS=$((DURATION_S * 1000))
                MAX_MESSAGES=$((RPS * DURATION_S))
                cp simple_produce_bench_template.json simple_produce_bench.json
                sed -ie "s/KAFKA_SERVER_ADDR/$KAFKA_SERVER_ADDR/g" simple_produce_bench.json
                sed -ie "s/TROGDOR_MPS/$RPS/g" simple_produce_bench.json
                sed -ie "s/TROGDOR_DURATION_MS/$DURATION_MS/g" simple_produce_bench.json
                sed -ie "s/TROGDOR_MAX_MESSAGES/$MAX_MESSAGES/g" simple_produce_bench.json
                echo "==================" >> trogdor_output.txt
                $KAFKA_DIR/bin/trogdor.sh agent -n node0 -c trogdor.conf --exec simple_produce_bench.json | tee -a trogdor_output.txt
              done
            ||| % kafka),
          systemslab.upload_artifact('trogdor_output.txt'),
          systemslab.barrier('kafka-finish'),
        ]
      }
    },
  }