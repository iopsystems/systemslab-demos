local systemslab = import 'systemslab.libsonnet';

local rpc_perf_config = {
    general: {
        protocol: 'ping',
        interval: 1,
        duration: 600,
        ratelimit: 1000,
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
        // We don't know the address of the redis job until its actually
        // running. This will be replaced by sed later on.
        endpoints: ['172.31.44.167:12321'],
    },
    client: {
        threads: 8,
        poolsize: error 'a poolsize must be specified',
        connect_timeout: 10000,
        request_timeout: 1000,
        read_buffer_size: 8192,
        write_buffer_size: 8192,
    },
    workload: {
        threads: 1,
        ratelimit: 1000,
        strict_ratelimit: true,
        keyspace: error 'a keyspace must be specified',
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
        keyspace = {
            weight: 1,
            commands: [
                { verb: 'ping', weight: 1 },
            ],
        },
        loadgen_config = rpc_perf_config {
            client+: {
                poolsize: connections,
            },
            workload+: {
                keyspace: [keyspace],
            },
        };

    {
        name: 'server_c%(connections)i' % {
            connections: connections,
        },
        jobs: {
            rpc_perf: {
                local loadgen = std.manifestTomlEx(loadgen_config, ''),

                host: {
                    // Only run on the c2d-16 instances
                    tags: ['c6gn.2xlarge', 'client'],
                },

                steps: [
                    # systemslab.bash('sudo ethtool -L ens4 combined 2'),

                    // Write out the toml configs for rpc-perf
                    systemslab.write_file('loadgen.toml', loadgen),

                    systemslab.bash('ulimit -n 100000'),

                    systemslab.bash('ulimit -a'),

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
                        taskset -ac 0-7 /usr/local/bin/rpc-perf loadgen.toml &

                        sleep 60

                        for qps in $(seq 20000 20000 400000); do
                            curl -s -X PUT http://localhost:9090/ratelimit/$qps
                            sleep 30
                        done

                        wait
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
                    tags: ['c6gn.2xlarge', 'server'],
                },
                steps: [
                    # systemslab.bash('sudo ethtool -L ens3 tx 2 rx 2'),

                    // Write out the toml configs for the server
                    systemslab.write_file('server.toml', server),

                    systemslab.bash('ulimit -n 100000'),

                    systemslab.bash('ulimit -a'),

                    systemslab.bash(
                        |||
                            taskset -ac 0-7 /usr/local/bin/pelikan_pingserver_rs server.toml
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
