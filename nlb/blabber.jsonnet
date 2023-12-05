local systemslab = import 'systemslab.libsonnet';

local rpc_perf_config = {
    general: {
        protocol: 'blabber',
        interval: 1,
        duration: 300,
        ratelimit: 1,
        json_output: 'output.json',
        admin: '0.0.0.0:9090',
        initial_seed: '0',
    },
    debug: {
        log_level: 'info',
        log_backup: 'rpc-perf.log.old',
        log_max_size: 1073741824,
    },
    target: {
        // We don't know the address of the server until it's actually running.
        // This will be replaced by sed later on.
        endpoints: ['SERVER_ADDR:12321'],
    },
    pubsub: {
        connect_timeout: 10000,
        publish_timeout: 1000,
        publisher_threads: 1,
        subscriber_threads: 2,
        publisher_poolsize: 1,
        publisher_concurrency: 1,
    },
    workload: {
        threads: 1,
        ratelimit: 1,
        strict_ratelimit: true,
        topics: error 'a keyspace must be specified',
    },
};

local server_config = {
    admin: {
        host: '127.0.0.1',
        port: '9999',
    },
    server: {
        host: '0.0.0.0',
        port: '12321',
        timeout: 100,
        nevent: 1024,
    },
    worker: {
        timeout: 100,
        nevent: 1024,
        threads: 8,
    },
};

function(connections='1000', klen='32', vlen='128', rw_ratio='8', threads='6')
    local args = {
        connections: connections,
        klen: klen,
        vlen: vlen,
        rw_ratio: rw_ratio,
        threads: threads,
    };
    local
        connections = std.parseInt(args.connections),
        topics = {
            weight: 1,
            topics: 1,
            topic_len: 1,
            message_len: 64,
            subscriber_poolsize: connections,
        },
        loadgen_config = rpc_perf_config {
            workload+: {
                topics: [topics],
            },
        };

    {
        name: 'blabber_c%(connections)i' % {
            connections: connections,
        },
        jobs: {
            rpc_perf: {
                local loadgen = std.manifestTomlEx(loadgen_config, ''),

                host: {
                    // Only run on the c2d-16 instances
                    tags: ['standard-2'],
                },

                steps: [
                    # systemslab.bash('sudo ethtool -L ens4 combined 2'),

                    // Write out the toml configs for rpc-perf
                    systemslab.write_file('loadgen.toml', loadgen),

                    systemslab.bash(
                        |||
                            sed -ie "s/SERVER_ADDR/$SERVER_ADDR/g" loadgen.toml
                        |||
                    ),

                    // Wait for the server to start
                    systemslab.barrier('server-start'),

                    // Wait 15s for the load balancer to be happy
                    systemslab.bash('sleep 15'),

                    // Now run the real benchmark
                    systemslab.bash(|||
                        ulimit -n 100000
                        ulimit -a
                        taskset -ac 0-7 /usr/local/bin/rpc-perf loadgen.toml
                    |||),

                    // Indicate to the server that we're done and it can exit
                    systemslab.barrier('server-finish'),

                    // Upload the rpc-perf output json file
                    systemslab.upload_artifact('output.json'),
                ],
            },

            server: {
                local server = std.manifestTomlEx(server_config, ''),

                host: {
                    tags: ['standard-2'],
                },
                steps: [
                    # systemslab.bash('sudo ethtool -L ens3 tx 2 rx 2'),

                    // Write out the toml configs for the server
                    systemslab.write_file('server.toml', server),

                    systemslab.bash(
                        |||
                            ulimit -n 100000
                            ulimit -a
                            taskset -ac 0-7 /usr/local/bin/blabber --threads 2 --publish-rate 1
                        |||,
                        background=true
                    ),

                    // Give the server instance a second to start up
                    systemslab.bash('sleep 1'),

                    // Hand things off to the client job
                    systemslab.barrier('server-start'),

                    // Wait for the client job to signal completion
                    systemslab.barrier('server-finish'),
                ],
            },
        },
    }
