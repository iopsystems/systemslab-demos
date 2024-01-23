local systemslab = import 'systemslab.libsonnet';
local bash = systemslab.bash;
local upload_artifact = systemslab.upload_artifact;

function(rpcperf_threads="4", rpcperf_tasks="20", kafka_network_threads="3", kafka_io_threads="8", partitions="1", topics="1", message_len="512", lingerms="0", storage="/mnt/gp3", kafka_version="2.13-3.6.1")
  {
    name : "kafka_client1_server1_maxqps",
    local configs = {
      client: 1,
      server: 1,
      kafka_version: kafka_version,
      rpcperf_threads: rpcperf_threads,      
      rpcperf_tasks: rpcperf_tasks,
      kafka_network_threads: kafka_network_threads,
      kafka_io_threads: kafka_io_threads,
      partitions: partitions,
      topics: topics,
      message_len: message_len,
      lingerms: lingerms,
      storage: storage,
    },
    metadata: configs,
    jobs: {
      local zookeeper_log = "%s/zookeeper_log" % configs.storage,
      local zookeeper_dir = "/opt/kafka_%s" % configs.kafka_version,
      zookeeper_server: {
        host: {
          tags: ["i3en.2xlarge"],
        },      
        steps: [
          systemslab.write_file('zookeeper.properties', importstr 'zookeeper.properties'),
          bash(
            |||
              echo "Start Zookeeper"                            
              ZOOKEEPER_LOG=%s
              ZOOKEEPER_DIR=%s
              sudo rm -rf $ZOOKEEPER_LOG
              sudo pkill -f java
              sleep 1               
              SED_ZOOKEEPER_LOG=$(sed 's/[\/&]/\\&/g' <<<"$ZOOKEEPER_LOG")
              sed -ie "s/ZOOKEEPER_LOG/$SED_ZOOKEEPER_LOG/g" zookeeper.properties
              LOG_DIR=$ZOOKEEPER_LOG $ZOOKEEPER_DIR/bin/zookeeper-server-start.sh zookeeper.properties&
              echo $! > ./zookeeper.pid
              sleep 5
            ||| % [zookeeper_log, zookeeper_dir]),
          systemslab.barrier('zookeeper-start'),
          systemslab.barrier('kafka-start'),
          systemslab.barrier('kafka-finish'),
        ],
      },
      kafka_server_1: {
        host: {
          tags: ['i3en.2xlarge'],
        },
        local kafka_log = "%s/kafka_log" % configs.storage,
        local kafka_dir = "/opt/kafka_%s" % configs.kafka_version,
        steps: [ 
          systemslab.barrier('zookeeper-start'),
          systemslab.write_file('server.properties', importstr 'server.properties'),        
          bash(
            |||
              echo "Start Kafka Broker"
              KAFKA_LOG=%s
              KAFKA_DIR=%s
              KAFKA_NETWORK_THREADS=%s
              KAFKA_IO_THREADS=%s
              sed -ie "s/BROKERID/0/g" server.properties
              sed -ie "s/ZOOKEEPER_SERVER_ADDR/$ZOOKEEPER_SERVER_ADDR/g" server.properties
              sed -ie "s/KAFKA_NETWORK_THREADS/$KAFKA_NETWORK_THREADS/g" server.properties
              sed -ie "s/KAFKA_IO_THREADS/$KAFKA_IO_THREADS/g" server.properties
              SED_KAFKA_LOG=$(sed 's/[\/&]/\\&/g' <<<"$KAFKA_LOG")                          
              sed -ie "s/KAFKA_LOG/$SED_KAFKA_LOG/g" server.properties
              sudo rm -rf $KAFKA_LOG
              sudo pkill -f java
              sleep 1
              $KAFKA_DIR/bin/kafka-server-start.sh server.properties > /dev/null&                         
              sleep 5
              $KAFKA_DIR/bin/kafka-cluster.sh  cluster-id  --bootstrap-server localhost:9092 > ./kafka-cluster-id.txt
            ||| % [kafka_log, kafka_dir, configs.kafka_network_threads, configs.kafka_io_threads] ),
          systemslab.upload_artifact('server.properties'),
          systemslab.barrier('kafka-start'),
          // waiting for the client to finish
          systemslab.barrier('kafka-finish'),
        ],
      },
      rpc_perf_1: {
        host: {
          tags: ['i3en.2xlarge'],
        },
        steps: [           
          systemslab.write_file('rpcperf-kafka.toml', importstr 'rpcperf-kafka.toml'),
          systemslab.barrier('kafka-start'),        
          bash(
            |||            
              RPCPERF_THREADS=%s
              RPCPERF_TASKS=%s
              PARTITIONS=%s
              LINGERMS=%s
              TOPICS=%s
              MESSAGE_LEN=%s
              DURATION_S=250
              RPC_CONFIG=rpcperf-kafka.toml              
              KAFKA_ENDPOINTS="[\"${KAFKA_SERVER_1_ADDR}:9092\"]"
              sed -ie "s/KAFKA_ENDPOINTS/$KAFKA_ENDPOINTS/g" $RPC_CONFIG                      
              sed -ie "s/DURATION_S/$DURATION_S/g" $RPC_CONFIG
              sed -ie "s/RPCPERF_THREADS/$RPCPERF_THREADS/g" $RPC_CONFIG
              sed -ie "s/RPCPERF_TASKS/$RPCPERF_TASKS/g" $RPC_CONFIG             
              sed -ie "s/PARTITIONS/$PARTITIONS/g" $RPC_CONFIG
              sed -ie "s/KAFKA_LINGER_MS/$LINGERMS/g" $RPC_CONFIG
              sed -ie "s/TOPICS/$TOPICS/g" $RPC_CONFIG
              sed -ie "s/MESSAGE_LEN/$MESSAGE_LEN/g" $RPC_CONFIG
              rpc-perf $RPC_CONFIG&
              # wait for 10seconds let all rpc-perf ready
              sleep 10
              for RPS in $(seq 10000 40000 300000); do
                for RPC_SERVER in ${RPC_PERF_1_ADDR}; do
                  echo "=======$RPS ${RPC_PERF_1_ADDR}======="
                  curl -s -X PUT http://$RPC_SERVER:9091/ratelimit/$RPS
                done
                sleep 30
              done
              wait              
            ||| % [configs.rpcperf_threads, configs.rpcperf_tasks, configs.partitions, configs.lingerms, configs.topics, configs.message_len]),
          systemslab.upload_artifact('rpcperf-kafka.toml'),                 
          systemslab.upload_artifact('output.json'),
          systemslab.barrier('kafka-finish'),
          # generate the experiment spec.json
        ],
      },
    },
  }
  