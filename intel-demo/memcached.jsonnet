local systemslab = import 'systemslab.libsonnet';

local rpc_perf_config = {
    general: {
        protocol: 'memcache',
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
        endpoints: ['MEMCACHED_ADDR:11211'],
    },
    client: {
        threads: 13,
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
        klen = std.parseInt(args.klen),
        vlen = std.parseInt(args.vlen),
        rw_ratio = std.parseJson(args.rw_ratio),
        threads = std.parseInt(args.threads),

        weights = if rw_ratio >= 1 then
            [std.round(10 * rw_ratio), 10]
        else
            [10, std.round(10 / rw_ratio)],
        read_weight = weights[0],
        write_weight = weights[1];

    assert std.isNumber(rw_ratio) : 'rw_ratio must be a number';

    local
        keyspace = {
            weight: 1,
            klen: klen,
            nkeys: 500000,
            vkind: 'bytes',
            vlen: vlen,
            commands: [
                { verb: 'get', weight: read_weight },
                { verb: 'set', weight: write_weight },
            ],
        },
        warmup_config = rpc_perf_config {
            general+: {
                // We don't need reporting to happen quite as often during warmup
                interval: 10,
                duration: 60,
                ratelimit: 100000,
            },
            client+: {
                poolsize: connections,
            },
            workload+: {
                ratelimit: 100000,
                keyspace: [
                    keyspace {
                        commands: [
                            { verb: 'get', weight: 10 },
                            { verb: 'set', weight: 90 },
                        ],
                    },
                ],
            },
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
        name: 'memcached_c%(connections)i_k%(klen)i_v%(vlen)i_%(rw)s%(ratio)f_t%(threads)i' % {
            connections: connections,
            klen: klen,
            vlen: vlen,
            rw: if rw_ratio >= 1 then 'r' else 'w',
            ratio: if rw_ratio >= 1 then read_weight else write_weight,
            threads: threads,
        },
        jobs: {
            rpc_perf: {
                local warmup = std.manifestTomlEx(warmup_config, ''),
                local loadgen = std.manifestTomlEx(loadgen_config, ''),

                host: {
                    // Only run on the c2d-16 instances
                    tags: ['c2d'],
                },

                steps: [
                    systemslab.bash('sudo ethtool -L ens4 combined 2'),

                    // Write out the toml configs for rpc-perf
                    systemslab.write_file('warmup.toml', warmup),
                    systemslab.write_file('loadgen.toml', loadgen),

                    systemslab.bash(
                        |||
                            sed -ie "s/MEMCACHED_ADDR/$MEMCACHED_ADDR/g" warmup.toml
                            sed -ie "s/MEMCACHED_ADDR/$MEMCACHED_ADDR/g" loadgen.toml
                        |||
                    ),

                    // Wait for the cache to start
                    systemslab.barrier('cache-start'),

                    // Now, warm up the cache
                    systemslab.bash('taskset -ac 2-15 rpc-perf warmup.toml'),

                    // Wait 60s for the rest of the stack to clean up any left over connections
                    systemslab.bash('sleep 60'),

                    // Now run the real benchmark
                    systemslab.bash(|||
                        taskset -ac 2-15 rpc-perf loadgen.toml &

                        sleep 60

                        for qps in $(seq 20000 20000 400000); do
                            curl -s -X PUT http://localhost:9090/ratelimit/$qps
                            sleep 30
                        done

                        wait
                    |||),

                    // Indicate to the redis job that we're done and it can exit
                    systemslab.barrier('cache-finish'),

                    // Upload the rpc-perf output json file
                    systemslab.upload_artifact('output.json'),
                ],
            },

            memcached: {
                host: {
                    tags: ['c3'],
                },
                steps: [
                    systemslab.bash('sudo ethtool -L ens3 tx 2 rx 2'),

                    systemslab.bash('ulimit -a'),

                    systemslab.bash(
                        |||
                            memcached               \
                                -o hashpower=26     \
                                -P pid              \
                                -t %(threads)i      \
                                -o no_modern        \
                                -m 8192             \
                                --conn-limit 8192
                        ||| % { threads: threads },
                        background=true
                    ),

                    // Give the redis instance a second to start up
                    systemslab.bash('sleep 1'),

                    // Hand things off to the rpc-perf instance
                    systemslab.barrier('cache-start'),

                    // Wait for the rpc-perf instance to finish
                    systemslab.barrier('cache-finish'),
                ],
            },
        },
    }
