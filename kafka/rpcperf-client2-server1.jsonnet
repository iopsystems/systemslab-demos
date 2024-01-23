local systemslab = import 'systemslab.libsonnet';
local bash = systemslab.bash;
local upload_artifact = systemslab.upload_artifact;

function(kafka="/opt/kafka", rpc_perf="/opt/rpc-perf/target/release/rpc-perf", kafka_host="", client_host="", zookeeper_host="", partition="10")  
  {
    name : "kafka_client1_server1",
    jobs: {
      zookeeper_server: {
        host: {
          tags: if zookeeper_host == "" then [] else [zookeepr_host],
        },      
        steps: [
          systemslab.write_file('zookeeper.properties', importstr 'zookeeper.properties'),
          bash(
            |||
              echo "Start Zookeeper"
              KAFKA_DIR=%s
              $KAFKA_DIR/bin/zookeeper-server-start.sh zookeeper.properties > zookeeper.log 2>&1 &
              echo $! > ./zookeeper.pid
              sleep 10
            ||| % kafka ),
          systemslab.barrier('zookeeper-start'),
          systemslab.barrier('kafka-start'),
          systemslab.barrier('kafka-finish'),
          systemslab.upload_artifact('zookeeper.log'),
          bash(
            |||
              echo "Terminate Zookeeper `cat ./zookeeper.pid`"
              cat ./zookeeper.pid | xargs kill -9                          
            |||
          ),
        ],
      },
      kafka_server: {
        host: {
          tags: if kafka_host == "" then [] else [kafka_host],
        },
        steps: [    
          systemslab.barrier('zookeeper-start'),
          systemslab.write_file('server.properties', importstr 'server.properties'),        
          bash(
            |||
              echo "Start Kafka Broker"
              KAFKA_DIR=%s
              sed -ie "s/ZOOKEEPER_SERVER_ADDR/$ZOOKEEPER_SERVER_ADDR/g" server.properties              
              $KAFKA_DIR/bin/kafka-server-start.sh server.properties > kafka.log 2>&1 &              
              echo $! > ./kafka.pid              
              sleep 20
              $KAFKA_DIR/bin/kafka-cluster.sh  cluster-id  --bootstrap-server localhost:9092 > ./kafka-cluster-id.txt
            ||| % kafka ),
          systemslab.barrier('kafka-start'),
          // waiting for the client to finish
          systemslab.barrier('kafka-finish'),
          bash(
            |||  
              echo "Terminate Kafka `cat ./kafka.pid`"
              cat ./kafka.pid | xargs kill -9
            |||
          ),
        ],
      },
      rpcperf_client_1: {
        host: {
          tags: if client_host == "" then [] else [client_host]
        },
        steps: [ 
          systemslab.write_file('rpcperf-kafka_template.toml', importstr 'rpcperf-kafka.toml'),
          systemslab.barrier('kafka-start'),
          bash(
            |||
              mkdir -p results
              RPC_PERF=%s
              # publisher/subscriber tasks
              for TASKS in 20 40 100; do
                for PARTITIONS in $(seq 1 10 100); do 
                  for LINGERMS in 0 1 2 3 4 5; do
                    for RPS in $(seq 20000 20000 200000); do
                      DURATION_S=30                
                      DURATION_MS=$((DURATION_S * 1000))
                      MAX_MESSAGES=$((RPS * DURATION_S))
                      PARAMETERS=tasks${TASKS}_partition${PARTITIONS}_lingerms${LINGERMS}_rps${RPS}
                      RPC_CONFIG=rpcperf-config_${PARAMETERS}.toml
                      cp rpcperf-kafka_template.toml $RPC_CONFIG
                      sed -ie "s/KAFKA_SERVER_ADDR/$KAFKA_SERVER_ADDR/g" $RPC_CONFIG
                      sed -ie "s/RPS/$RPS/g" $RPC_CONFIG
                      sed -ie "s/DURATION_S/$DURATION_S/g" $RPC_CONFIG
                      sed -ie "s/PUBLISHER_TASKS/$TASKS/g" $RPC_CONFIG
                      sed -ie "s/SUBSCRIBER_TASKS/$TASKS/g" $RPC_CONFIG
                      sed -ie "s/PARTITIONS/$PARTITIONS/g" $RPC_CONFIG
                      sed -ie "s/KAFKA_LINGER_MS/$LINGERMS/g" $RPC_CONFIG
                      echo "Executing $RPC_CONFIG"               
                      LOG_FILE=kafka_client1_server1_${PARAMETERS}.stdout
                      JSON_FILE=kafka_client1_server1_${PARAMETERS}.json
                      $RPC_PERF $RPC_CONFIG | tee -a $LOG_FILE
                      cp stats.json $JSON_FILE
                      mv $RPC_CONFIG ./results
                      mv $LOG_FILE ./results
                      mv $JSON_FILE ./results
                    done
                  done
                done
              done
              tar -czvf kafka_client1_server1.tar.gz ./results
            ||| % rpc_perf),
          systemslab.upload_artifact('kafka_client1_server1.tar.gz'),         
          systemslab.barrier('kafka-finish'),
          # generate the experiment spec.json
        ],
      },
      rpcperf_client_2: {
        host: {
          tags: if client_host == "" then [] else [client_host]
        },
        steps: [ 
          systemslab.write_file('rpcperf-kafka_template.toml', importstr 'rpcperf-kafka.toml'),
          systemslab.barrier('kafka-start'),
          bash(
            |||
              mkdir -p results
              RPC_PERF=%s
              # publisher/subscriber tasks
              for TASKS in 20 40 100; do
                for PARTITIONS in $(seq 1 10 100); do 
                  for LINGERMS in 0 1 2 3 4 5; do
                    for RPS in $(seq 20000 20000 200000); do
                      DURATION_S=30                
                      DURATION_MS=$((DURATION_S * 1000))
                      MAX_MESSAGES=$((RPS * DURATION_S))
                      PARAMETERS=tasks${TASKS}_partition${PARTITIONS}_lingerms${LINGERMS}_rps${RPS}
                      RPC_CONFIG=rpcperf-config_${PARAMETERS}.toml
                      cp rpcperf-kafka_template.toml $RPC_CONFIG
                      sed -ie "s/KAFKA_SERVER_ADDR/$KAFKA_SERVER_ADDR/g" $RPC_CONFIG
                      sed -ie "s/RPS/$RPS/g" $RPC_CONFIG
                      sed -ie "s/DURATION_S/$DURATION_S/g" $RPC_CONFIG
                      sed -ie "s/PUBLISHER_TASKS/$TASKS/g" $RPC_CONFIG
                      sed -ie "s/SUBSCRIBER_TASKS/$TASKS/g" $RPC_CONFIG
                      sed -ie "s/PARTITIONS/$PARTITIONS/g" $RPC_CONFIG
                      sed -ie "s/KAFKA_LINGER_MS/$LINGERMS/g" $RPC_CONFIG
                      echo "Executing $RPC_CONFIG"               
                      LOG_FILE=kafka_client1_server1_${PARAMETERS}.stdout
                      JSON_FILE=kafka_client1_server1_${PARAMETERS}.json
                      $RPC_PERF $RPC_CONFIG | tee -a $LOG_FILE
                      cp stats.json $JSON_FILE
                      mv $RPC_CONFIG ./results
                      mv $LOG_FILE ./results
                      mv $JSON_FILE ./results
                    done
                  done
                done
              done
              tar -czvf kafka_client1_server1.tar.gz ./results
            ||| % rpc_perf),
          systemslab.upload_artifact('kafka_client1_server1.tar.gz'),         
          systemslab.barrier('kafka-finish'),
          # generate the experiment spec.json
        ],
      },      
    },
  }
  