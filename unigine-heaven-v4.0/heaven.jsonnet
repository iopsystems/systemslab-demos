local systemslab = import 'systemslab.libsonnet';

function(width='1920', height='1080', quality='ULTRA', tessellation='EXTREME', antialiasing='8', powercap='0', gpu='l4')
    local args = {
        width: width,
        height: height,
        quality: quality,
        tessellation: tessellation,
        antialiasing: antialiasing,
        powercap: powercap,
        gpu: gpu,
    };
    local
        width = std.parseInt(args.width),
        height = std.parseInt(args.height),
        powercap = std.parseInt(args.powercap),
        antialiasing = std.parseInt(args.antialiasing);
    {
        name: 'unigen-heaven-v4.0_%(gpu)s_%(powercap)iW_%(width)ix%(height)i_%(antialiasing)i_%(quality)s_%(tessellation)s' % {
            width: width,
            height: height,
            quality: quality,
            tessellation: tessellation,
            antialiasing: antialiasing,
            powercap: powercap,
            gpu: gpu,
        },
        jobs: {
            heaven: {
                host: {
                    tags: ['%(gpu)s' % { gpu: gpu }],
                },
                steps: [
                    systemslab.bash(
                        |||
                            export HOME=`pwd`
                            echo "starting X11..."
                            startx &
                            export XPID=$!
                            sleep 5
                            export DISPLAY=`ps -elf | grep Xorg | grep -v grep | awk '{print $18}'.0`
                            echo "X11 running on display $DISPLAY with PID $XPID"

                            echo "setting powercap"
                            if [ %(powercap)i -eq 0 ]; then
                                sudo nvidia-smi -pl `nvidia-smi -q | grep "Default Power Limit" | awk '{print $5}' | head -1`
                            else
                                sudo nvidia-smi -pl %(powercap)i
                            fi

                            echo "extracting benchmark..."
                            tar xzf /usr/local/share/heaven.tgz
                            cd Unigine_Heaven-4.0-Advanced/automation

                            echo "running benchmark..."
                            ./single_run.py %(width)i %(height)i %(antialiasing)i %(quality)s %(tessellation)s
                            kill $XPID
                        ||| % {
                            width: width,
                            height: height,
                            quality: quality,
                            tessellation: tessellation,
                            antialiasing: antialiasing,
                            powercap: powercap,
                        },
                        background=false
                    ),

                    // Upload the artifacts
                    systemslab.upload_artifact('reports/frames.log'),
                    systemslab.upload_artifact('reports/temperature.log'),
                    systemslab.upload_artifact('reports/single_run_log.csv'),
                ],
            },
        },
    }
