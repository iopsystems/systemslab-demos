local systemslab = import 'systemslab.libsonnet';

local rpc_perf_config = {
    general: {
        protocol: 'blabber',
        interval: 1,
        duration: 60,
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
        endpoints: ['SERVER_ADDR:12321'],
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
                    tags: ['alpha'],
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
                        /usr/local/bin/rpc-perf loadgen.toml
                    |||),

                    // Indicate to the server that we're done and it can exit
                    systemslab.barrier('server-finish'),

                    // Upload the rpc-perf output json file
                    systemslab.upload_artifact('output.json'),
                ],
            },

            server: {
                host: {
                    tags: ['bravo'],
                },
                steps: [
                    # systemslab.bash('sudo ethtool -L ens3 tx 2 rx 2'),

                    systemslab.bash(
                        |||
                            export RUST_BACKTRACE=full
                            ulimit -n 100000
                            ulimit -a
                            /usr/local/bin/blabber --threads 8 --publish-rate 1 --fanout 7
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
