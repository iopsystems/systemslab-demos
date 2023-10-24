local systemslab = import 'systemslab.libsonnet';
local bash = systemslab.bash;
local upload_artifact = systemslab.upload_artifact;

function(kafka="~/kafka", kafka_host="")  
  {
    name : "Test_Kafka_Server",
    jobs: {
      kafka_server: {
        host: {
          tags: if kafka_host == "" then [] else [kafka_host],
        },
        steps: [        
          // TODO, put the environment setting to a separate file
          // set the governor to performance          
          bash('for f in  /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do sudo bash -c "echo performance > $f"; done'),
          systemslab.write_file('zookeeper.properties', importstr 'zookeeper.properties'),
          systemslab.write_file('server.properties', importstr 'server.properties'),          
          bash(
            |||
              echo "Start Zookeeper"
              KAFKA_DIR=%s
              $KAFKA_DIR/bin/zookeeper-server-start.sh zookeeper.properties &
              echo $! > ./zookeeper.pid
              sleep 3
              echo "Start Kafka Broker"
              $KAFKA_DIR/bin/kafka-server-start.sh server.properties &
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
              echo "Kafka address is $KAFKA_SERVER_ADDR"
              echo "Terminate Zookeeper `cat ./zookeeper.pid`"
              cat ./zookeeper.pid | xargs kill
              echo "Terminate Kafka `cat ./kafka.pid`"
              cat ./kafka.pid | xargs kill
            |||
          ),
        ],
      },
    },
  }
