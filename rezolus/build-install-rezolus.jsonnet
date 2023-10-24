local systemslab = import 'systemslab.libsonnet';

local bash = systemslab.bash;

function(repo="https://github.com/iopsystems/rezolus.git", branch="main", host="", target="")
  {
    name : 'build_and_install_rezolus|' + 'repo:'+repo + '|branch:' + branch + '|host:' + host + '|target:' + target,
    jobs: {
      rezolus: {
          "host": {
            tags: if host == "" then [] else [host],  
          },
        steps: [       
            bash(
            |||
              source ~/.profile            
              git clone %s
              cd rezolus
              git checkout %s
              cargo build --release --features bpf
            ||| %[repo, branch]),
        ] + (if target == "" then [] else [
          bash(
            |||
              sudo mkdir -p $(dirname %s)
              sudo cp ./rezolus/target/release/rezolus %s/
            ||| %[target, target]
          ),
        ])
      },
    },
  }