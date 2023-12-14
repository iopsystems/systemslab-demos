local systemslab = import 'systemslab.libsonnet';

local blabber_config = {
    threads: 1,
    queue_depth: 128,
    fanout: 1,
    max_delay_us: 0,

    server: {
        addr: '0.0.0.0:12321',
    },
    publisher: {
        rate: 1,
        message_len: 32,
    },
    debug: {
        log_level: 'info',
        log_backup: 'rpc-perf.log.old',
        log_max_size: 1073741824,
    },
};

local rpc_perf_config = {
    general: {
        protocol: 'blabber',
        interval: 60,
        duration: 180,
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
        
        // endpoints: ['nlb-0-44b74801d0068ea4.elb.us-west-2.amazonaws.com:12321'],
        endpoints: ['SERVER_1_ADDR:12321','SERVER_2_ADDR:12321','SERVER_3_ADDR:12321','SERVER_4_ADDR:12321','SERVER_5_ADDR:12321'],
    },
    pubsub: {
        connect_timeout: 10000,
        publish_timeout: 1000,
        publisher_threads: 1,
        subscriber_threads: 8,
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

function(connections='1000', threads='6', queue_depth='128', fanout='1', max_delay_us='0', publish_rate='1', message_len='32')
    local args = {
        connections: connections,
        threads: threads,
        queue_depth: queue_depth,
        fanout: fanout,
        max_delay_us: max_delay_us,
        publish_rate: publish_rate,
        message_len: message_len,
    };
    local
        connections = std.parseInt(args.connections),
        threads = std.parseInt(args.threads),
        queue_depth = std.parseInt(args.queue_depth),
        fanout = std.parseInt(args.fanout),
        max_delay_us = std.parseInt(args.max_delay_us),
        publish_rate = std.parseInt(args.publish_rate),
        message_len = std.parseInt(args.message_len),

        topics = {
            weight: 1,
            topics: 1,
            topic_len: 1,
            message_len: 64,
            subscriber_poolsize: connections,
        },

        server_config = blabber_config {
            threads: threads,
            queue_depth: queue_depth,
            fanout: fanout,
            max_delay_us: max_delay_us,

            publisher+: {
                rate: publish_rate,
                message_len: message_len,
            },
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
            rpc_perf_1: {
                local loadgen = std.manifestTomlEx(loadgen_config, ''),

                host: {
                    // Only run on the c2d-16 instances
                    tags: ['c6gn.2xlarge'],
                },

                steps: [
                    # systemslab.bash('sudo ethtool -L ens4 combined 2'),

                    // Write out the toml configs for rpc-perf
                    systemslab.write_file('loadgen.toml', loadgen),

                    systemslab.bash(
                        |||
                            sed -ie "s/SERVER_1_ADDR/$SERVER_1_ADDR/g" loadgen.toml
                            sed -ie "s/SERVER_2_ADDR/$SERVER_2_ADDR/g" loadgen.toml
                            sed -ie "s/SERVER_3_ADDR/$SERVER_3_ADDR/g" loadgen.toml
                            sed -ie "s/SERVER_4_ADDR/$SERVER_4_ADDR/g" loadgen.toml
                            sed -ie "s/SERVER_5_ADDR/$SERVER_5_ADDR/g" loadgen.toml
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
                        /usr/local/bin/rpc-perf loadgen.toml
                    |||),

                    // Indicate to the server that we're done and it can exit
                    systemslab.barrier('server-finish'),

                    // Upload the rpc-perf output json file
                    systemslab.upload_artifact('output.json'),
                ],
            },

            rpc_perf_2: {
                local loadgen = std.manifestTomlEx(loadgen_config, ''),

                host: {
                    // Only run on the c2d-16 instances
                    tags: ['c6gn.2xlarge'],
                },

                steps: [
                    # systemslab.bash('sudo ethtool -L ens4 combined 2'),

                    // Write out the toml configs for rpc-perf
                    systemslab.write_file('loadgen.toml', loadgen),

                    systemslab.bash(
                        |||
                            sed -ie "s/SERVER_1_ADDR/$SERVER_1_ADDR/g" loadgen.toml
                            sed -ie "s/SERVER_2_ADDR/$SERVER_2_ADDR/g" loadgen.toml
                            sed -ie "s/SERVER_3_ADDR/$SERVER_3_ADDR/g" loadgen.toml
                            sed -ie "s/SERVER_4_ADDR/$SERVER_4_ADDR/g" loadgen.toml
                            sed -ie "s/SERVER_5_ADDR/$SERVER_5_ADDR/g" loadgen.toml
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
                        /usr/local/bin/rpc-perf loadgen.toml
                    |||),

                    // Indicate to the server that we're done and it can exit
                    systemslab.barrier('server-finish'),

                    // Upload the rpc-perf output json file
                    systemslab.upload_artifact('output.json'),
                ],
            },

            rpc_perf_3: {
                local loadgen = std.manifestTomlEx(loadgen_config, ''),

                host: {
                    // Only run on the c2d-16 instances
                    tags: ['c6gn.2xlarge'],
                },

                steps: [
                    # systemslab.bash('sudo ethtool -L ens4 combined 2'),

                    // Write out the toml configs for rpc-perf
                    systemslab.write_file('loadgen.toml', loadgen),

                    systemslab.bash(
                        |||
                            sed -ie "s/SERVER_1_ADDR/$SERVER_1_ADDR/g" loadgen.toml
                            sed -ie "s/SERVER_2_ADDR/$SERVER_2_ADDR/g" loadgen.toml
                            sed -ie "s/SERVER_3_ADDR/$SERVER_3_ADDR/g" loadgen.toml
                            sed -ie "s/SERVER_4_ADDR/$SERVER_4_ADDR/g" loadgen.toml
                            sed -ie "s/SERVER_5_ADDR/$SERVER_5_ADDR/g" loadgen.toml
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
                        /usr/local/bin/rpc-perf loadgen.toml
                    |||),

                    // Indicate to the server that we're done and it can exit
                    systemslab.barrier('server-finish'),

                    // Upload the rpc-perf output json file
                    systemslab.upload_artifact('output.json'),
                ],
            },

            rpc_perf_4: {
                local loadgen = std.manifestTomlEx(loadgen_config, ''),

                host: {
                    // Only run on the c2d-16 instances
                    tags: ['c6gn.2xlarge'],
                },

                steps: [
                    # systemslab.bash('sudo ethtool -L ens4 combined 2'),

                    // Write out the toml configs for rpc-perf
                    systemslab.write_file('loadgen.toml', loadgen),

                    systemslab.bash(
                        |||
                            sed -ie "s/SERVER_1_ADDR/$SERVER_1_ADDR/g" loadgen.toml
                            sed -ie "s/SERVER_2_ADDR/$SERVER_2_ADDR/g" loadgen.toml
                            sed -ie "s/SERVER_3_ADDR/$SERVER_3_ADDR/g" loadgen.toml
                            sed -ie "s/SERVER_4_ADDR/$SERVER_4_ADDR/g" loadgen.toml
                            sed -ie "s/SERVER_5_ADDR/$SERVER_5_ADDR/g" loadgen.toml
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
                        /usr/local/bin/rpc-perf loadgen.toml
                    |||),

                    // Indicate to the server that we're done and it can exit
                    systemslab.barrier('server-finish'),

                    // Upload the rpc-perf output json file
                    systemslab.upload_artifact('output.json'),
                ],
            },

            rpc_perf_5: {
                local loadgen = std.manifestTomlEx(loadgen_config, ''),

                host: {
                    // Only run on the c2d-16 instances
                    tags: ['c6gn.2xlarge'],
                },

                steps: [
                    # systemslab.bash('sudo ethtool -L ens4 combined 2'),

                    // Write out the toml configs for rpc-perf
                    systemslab.write_file('loadgen.toml', loadgen),

                    systemslab.bash(
                        |||
                            sed -ie "s/SERVER_1_ADDR/$SERVER_1_ADDR/g" loadgen.toml
                            sed -ie "s/SERVER_2_ADDR/$SERVER_2_ADDR/g" loadgen.toml
                            sed -ie "s/SERVER_3_ADDR/$SERVER_3_ADDR/g" loadgen.toml
                            sed -ie "s/SERVER_4_ADDR/$SERVER_4_ADDR/g" loadgen.toml
                            sed -ie "s/SERVER_5_ADDR/$SERVER_5_ADDR/g" loadgen.toml
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
                        /usr/local/bin/rpc-perf loadgen.toml
                    |||),

                    // Indicate to the server that we're done and it can exit
                    systemslab.barrier('server-finish'),

                    // Upload the rpc-perf output json file
                    systemslab.upload_artifact('output.json'),
                ],
            },
            server_1: {
                local server = std.manifestTomlEx(server_config, ''),

                host: {
                    tags: ['c6g.2xlarge','nlb-0'],
                },
                steps: [
                    systemslab.write_file('server.toml', server),

                    systemslab.bash(
                        |||
                            export RUST_BACKTRACE=full
                            ulimit -n 200000
                            ulimit -a
                            /usr/local/bin/blabber server.toml
                        |||,
                        background=true
                    ),

                    // Give the server instance a second to start up
                    systemslab.bash('sleep 5'),

                    // Hand things off to the client job
                    systemslab.barrier('server-start'),

                    // Wait for the client job to signal completion
                    systemslab.barrier('server-finish'),
                ],
            },
            server_2: {
                local server = std.manifestTomlEx(server_config, ''),

                host: {
                    tags: ['c6g.2xlarge','nlb-0'],
                },
                steps: [
                    systemslab.write_file('server.toml', server),

                    systemslab.bash(
                        |||
                            export RUST_BACKTRACE=full
                            ulimit -n 200000
                            ulimit -a
                            /usr/local/bin/blabber server.toml
                        |||,
                        background=true
                    ),

                    // Give the server instance a second to start up
                    systemslab.bash('sleep 5'),

                    // Hand things off to the client job
                    systemslab.barrier('server-start'),

                    // Wait for the client job to signal completion
                    systemslab.barrier('server-finish'),
                ],
            },
            server_3: {
                local server = std.manifestTomlEx(server_config, ''),

                host: {
                    tags: ['c6g.2xlarge','nlb-0'],
                },
                steps: [
                    systemslab.write_file('server.toml', server),

                    systemslab.bash(
                        |||
                            export RUST_BACKTRACE=full
                            ulimit -n 200000
                            ulimit -a
                            /usr/local/bin/blabber server.toml
                        |||,
                        background=true
                    ),

                    // Give the server instance a second to start up
                    systemslab.bash('sleep 5'),

                    // Hand things off to the client job
                    systemslab.barrier('server-start'),

                    // Wait for the client job to signal completion
                    systemslab.barrier('server-finish'),
                ],
            },
            server_4: {
                local server = std.manifestTomlEx(server_config, ''),

                host: {
                    tags: ['c6g.2xlarge','nlb-0'],
                },
                steps: [
                    systemslab.write_file('server.toml', server),

                    systemslab.bash(
                        |||
                            export RUST_BACKTRACE=full
                            ulimit -n 200000
                            ulimit -a
                            /usr/local/bin/blabber server.toml
                        |||,
                        background=true
                    ),

                    // Give the server instance a second to start up
                    systemslab.bash('sleep 5'),

                    // Hand things off to the client job
                    systemslab.barrier('server-start'),

                    // Wait for the client job to signal completion
                    systemslab.barrier('server-finish'),
                ],
            },
            server_5: {
                local server = std.manifestTomlEx(server_config, ''),

                host: {
                    tags: ['c6g.2xlarge','nlb-0'],
                },
                steps: [
                    systemslab.write_file('server.toml', server),

                    systemslab.bash(
                        |||
                            export RUST_BACKTRACE=full
                            ulimit -n 200000
                            ulimit -a
                            /usr/local/bin/blabber server.toml
                        |||,
                        background=true
                    ),

                    // Give the server instance a second to start up
                    systemslab.bash('sleep 5'),

                    // Hand things off to the client job
                    systemslab.barrier('server-start'),

                    // Wait for the client job to signal completion
                    systemslab.barrier('server-finish'),
                ],
            },
        },
    }
