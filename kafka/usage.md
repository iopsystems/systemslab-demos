# build and install Kafka and Trogdor (build-install-kafka.jsonnet)
* --param repo: The Kafka Repo, default https://github.com/apache/kafka.git
* --param branch: The Kafka branch, default trunk
* --param host: The host to build and install Kafka and Trogdor
* --param target: The Kafka installation path, default ~/kafka
```
systemslab --systemslab-url http://localhost submit --wait ./build-install-kafka.jsonnet --param "host=TARGET_HOST"
```

# build and install rpc-perf (build-install-rpcperf.jsonnet)
* --param repo: The rpc-perf Repo, default https://github.com/iopsystems/rpc-perf.git
* --param branch: The rpc-perf branch, default main
* --param host: The host to build and install rpc-perf
* --param target: The rpc-perf installation path, default ~/bin/rpc-perf
```
systemslab --systemslab-url http://localhost submit --wait ./build-install-rpcperf.jsonnet --param "host=TARGET_HOST"
```

# Run Kafka producing benchmark with Trogdor or rpc-perf (trogdor-produce-benchmark.jsonnet and rpcperf-produce-benchmark.jsonnet)
* --param kafka: The path of installed Kafka package, default ~/kafka
* --param kafka_host: The host to run the Kafka broker
* --param client_host: The host to run the Trogdor client or the rpc-perf client
```
# Build and install Kafka and Trogdor on the server host and the client host
systemslab --systemslab-url http://localhost submit --wait ./build-install-kafka.jsonnet --param "host=SERVER_HOST"
systemslab --systemslab-url http://localhost submit --wait ./build-install-kafka.jsonnet --param "host=CLIENT_HOST"
# Run the benchmark with the Trogdor client
systemslab --systemslab-url http://localhost submit --wait ./trogdor-produce-benchmark.jsonnet --param "kafka_host=SERVER_HOST" --param "client_host=CLIENT_HOST"
# Run the benchmark with the rpc-perf client
systemslab --systemslab-url http://localhost submit --wait ./rpcperf-produce-benchmark.jsonnet --param "kafka_host=SERVER_HOST" --param "client_host=CLIENT_HOST"
```