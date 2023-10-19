local systemslab = import 'systemslab.libsonnet';
local bash = systemslab.bash;
local upload_artifact = systemslab.upload_artifact;

function(rezolus="rezolus", host="", perf="perf")
  local rezolus_toml = importstr 'config.toml';
  {
    name : 'profile_rezolus' + '|rezolus:' + rezolus + '|host:' + host,
    jobs: {
      rezolus_server: {
        host: {
          tags: if host == "" then [] else [host],     
        },
        steps: [
          # Exit if there is a running Rezolus
          bash('! pgrep rezolus'),
          bash('cat > ./config.toml << EOM\n' + rezolus_toml + '\nEOM'),
          bash('for f in  /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do sudo bash -c "echo performance > $f"; done'),
          bash(
            |||      
              sudo %s ./config.toml > rezolus.log 2>&1&   
            ||| % rezolus, background=true),
          // query hardware info         
          bash(
            |||           
              sleep 1
              curl localhost:4242/hardware_info > hwinfo.json          
            |||),
          upload_artifact('./hwinfo.json'),
          bash(
            |||
              sudo %s stat -p `pgrep rezolus` -e task-clock,cycles,instructions -I 10 -j -o rezolus_perf.json -- sleep 60
            ||| % perf
          ),
          upload_artifact('./rezolus_perf.json'),
          bash(
            |||
              sudo kill `pgrep rezolus`
            |||
          ),
        ],
      },
    },
  }