local systemslab = import 'systemslab.libsonnet';

function(model='Llama-2-7B', quantization='Q4_K_M', powercap='0', repetitions='60', length='128', gpu='rtx2080ti')
    local args = {
        model: model,
        quantization: quantization,
        powercap: powercap,
        repetitions: repetitions,
        length: length,
        gpu: gpu,
    };
    local
        length = std.parseInt(args.length),
        powercap = std.parseInt(args.powercap),
        repetitions = std.parseInt(args.repetitions);
    {
        name: 'llamabench_%(model)s_%(quantization)s_%(powercap)iW_%(gpu)s_r%(repetitions)i_l%(length)i' % {
            model: model,
            quantization: quantization,
            powercap: powercap,
            repetitions: repetitions,
            length: length,
            gpu: gpu,
        },
        jobs: {
            llamabench: {
                host: {
                    tags: ['%(gpu)s' % { gpu: gpu }],
                },
                steps: [
                    systemslab.bash(
                        |||
                            echo "setting powercap..."
                            if [ %(powercap)i -eq 0 ]; then
                                sudo nvidia-smi -pl `nvidia-smi -q | grep "Default Power Limit" | awk '{print $5}' | head -1`
                            else
                                sudo nvidia-smi -pl %(powercap)i
                            fi

                            echo "running benchmark..."
                            /usr/local/bin/llama-bench -m /mnt/%(model)s-GGUF/*.%(quantization)s.gguf -p 0 -r %(repetitions)i -n %(length)i -o json > output.json
                        ||| % {
                            model: model,
                            quantization: quantization,
                            powercap: powercap,
                            repetitions: repetitions,
                            length: length,
                        },
                        background=false
                    ),

                    // Upload the artifacts
                    systemslab.upload_artifact('output.json'),
                ],
            },
        },
    }
