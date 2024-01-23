local systemslab = import 'systemslab.libsonnet';
local bash = systemslab.bash;
local upload_artifact = systemslab.upload_artifact;

function(rpcperf_threads="4", rpcperf_tasks="20", kafka_network_threads="3", kafka_io_threads="8", partitions="1", topics="1", message_len="512", lingerms="0", storage="/mnt/gp3", kafka_version="2.13-3.6.1")
  {
    name : "kafka_client1_server1",
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
      local zookeeper_dir = "/home/ubuntu/kafka_%s" % configs.kafka_version,
      zookeeper_server: {
        host: {
          tags: ["i3en.2xlarge"],
        },      
        steps: [
          systemslab.write_file('zookeeper.properties', importstr 'zookeeper.properties'),
          bash(
            |||
              echo "Start Zookeeper"              
              LOG_DIR=%s %s/bin/zookeeper-server-start.sh zookeeper.properties&
              echo $! > ./zookeeper.pid
              sleep 10
            ||| % [zookeeper_log, zookeeper_dir]),
          systemslab.barrier('zookeeper-start'),
          systemslab.barrier('kafka-start'),
          systemslab.barrier('kafka-finish'),
        ],
      },
      kafka_server_1: {
        host: {
          tags: ["i3en.2xlarge"],
        },
        local kafka_log = "%s/kafka_log" % configs.storage,
        local kafka_dir = "/home/ubuntu/kafka_%s" % configs.kafka_version,
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
              sed -ie "s/ZOOKEEPER_SERVER_ADDR/$ZOOKEEPER_SERVER_ADDR/g" server.properties
              sed -ie "s/KAFKA_NETWORK_THREADS/$KAFKA_NETWORK_THREADS/g" server.properties
              sed -ie "s/KAFKA_IO_THREADS/$KAFKA_IO_THREADS/g" server.properties
              LOG_DIR=$KAFKA_LOG $KAFKA_DIR/bin/kafka-server-start.sh server.properties&                         
              sleep 20
              LOG_DIR=$KAFKA_LOG $KAFKA_DIR/bin/kafka-cluster.sh  cluster-id  --bootstrap-server localhost:9092 > ./kafka-cluster-id.txt
            ||| % [kafka_log, kafka_dir, configs.kafka_network_threads, configs.kafka_io_threads] ),
          systemslab.barrier('kafka-start'),
          // waiting for the client to finish
          systemslab.barrier('kafka-finish'),
        ],
      },
    },
  }