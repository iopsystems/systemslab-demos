#!/bin/bash

for PARTITIONS in 1 10 20 40 80 100; do
  for LINGERMS in 0 2 5 10; do
    for RPCPERF_THREADS in 8; do
      for RPCPERF_TASKS in 4000; do
        for TOPICS in 1; do
          for STORAGE in /mnt/gp3 /mnt/data-1; do             
            cmd="systemslab --systemslab-url http://localhost submit ./rpcperf-client1-server1-maxqps.jsonnet --param topics=$TOPICS --param partitions=$PARTITIONS --param storage=$STORAGE --param lingerms=$LINGERMS --param rpcperf_tasks=$RPCPERF_TASKS --param rpcperf_threads=$RPCPERF_THREADS"            
            $cmd
          done
        done
        #systemslab --systemslab-url http://localhost submit ./rpcperf-client1-server1-maxqps.jsonnet --param "partitions=$"  --param "lingerms=1" --param "rpcperf_tasks=1000" --param "rpcperf_threads=8"
      done
    done
  done
done
