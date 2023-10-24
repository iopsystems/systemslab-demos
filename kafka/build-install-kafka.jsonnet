local systemslab = import 'systemslab.libsonnet';

local bash = systemslab.bash;

function(repo="https://github.com/apache/kafka.git", branch="trunk", host="", target="~/")
  {
    name : 'build_and_install_kafka|' + 'repo:'+repo + '|branch:' + branch + '|host:' + host + '|target:' + target,
    jobs: {
      build_and_install_kafka: {
          "host": {
            tags: if host == "" then [] else [host],  
          },
        steps: [       
            bash(
            |||            
              git clone %s kafka
              cd kafka
              git checkout %s
              ./gradlew jar              
            ||| %[repo, branch]),
        ] + (if target == "" then [] else [
          bash(
            |||
              TARGET_DIR=%s
              mkdir -p $(dirname $TARGET_DIR)
              rm -r $TARGET_DIR/kafka
              cp -r -a ./kafka $TARGET_DIR/kafka
            ||| %target
          ),
        ])
      },
    },
  }