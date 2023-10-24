local systemslab = import 'systemslab.libsonnet';

local bash = systemslab.bash;

function(repo="https://github.com/iopsystems/rpc-perf.git", branch="main", host="", target="~/bin/rpc-perf")
  {
    name : 'build_and_install_rpc_perf|' + 'repo:'+repo + '|branch:' + branch + '|host:' + host + '|target:' + target,
    jobs: {
      rpcperf: {
          "host": {
            tags: if host == "" then [] else [host],  
          },
        steps: [       
            bash(
            |||
              source ~/.profile            
              git clone %s rpc-perf
              cd rpc-perf
              git checkout %s
              cargo build --release
            ||| %[repo, branch]),
        ] + (if target == "" then [] else [
          bash(
            |||
              TARGET_FILE=%s
              rm $TARGET_FILE || true      
              mkdir -p $(dirname $TARGET_FILE)
              sudo cp ./rpc-perf/target/release/rpc-perf $TARGET_FILE
            ||| %target
          ),
        ]),
      },
    },
  }