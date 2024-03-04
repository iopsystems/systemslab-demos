function(model='Llama-2-7B', quantization='Q4_K_M', powercap='0', repetitions='60', length='128', gpu='rtx2080ti', autodownload='1')
    local args = {
        model: model,
        quantization: quantization,
        powercap: powercap,
        repetitions: repetitions,
        length: length,
        gpu: gpu,
        autodownload: autodownload,
    };
    local
        length = std.parseInt(args.length),
        powercap = std.parseInt(args.powercap),
        repetitions = std.parseInt(args.repetitions),
        autodownload = std.parseInt(args.autodownload);
    {
        name: 'bench_%(model)s_%(quantization)s_%(powercap)iW_%(gpu)s_r%(repetitions)i_l%(length)i' % {
            model: model,
            quantization: quantization,
            powercap: powercap,
            repetitions: repetitions,
            length: length,
            gpu: gpu,
        },
        jobs: {
            bench: {
                host: {
                    tags: ['%(gpu)s' % { gpu: gpu }],
                },
                steps: [
                    systemslab.bash(
                        |||
                            echo "environment setup..."
                            export HOME=`pwd`

                            echo "setting powercap..."
                            if [ %(powercap)i -eq 0 ]; then
                                sudo nvidia-smi -pl `nvidia-smi -q | grep "Default Power Limit" | awk '{print $5}' | head -1`
                            else
                                sudo nvidia-smi -pl %(powercap)i
                            fi

                            MODEL="%(model)s-GGUF"
                            HFUSER="TheBloke"
                            MODEL_FAMILY=`echo ${MODEL} | awk -F- '{print $1}'`
                            QUANTIZATION="%(quantization)s"

                            if [ "${MODEL_FAMILY}" == "OpenLlama" ]; then
                                HFUSER="brayniac"
                            fi

                            if [ %(autodownload)i -eq 1 ]; then
                                echo "downloading model..."
                                huggingface-cli download ${HFUSER}/${MODEL} --local-dir . --local-dir-use-symlinks False --include="*${QUANTIZATION}.gguf"
                                ls *.gguf
                            fi

                            PATHPREFIX=".";

                            echo "running benchmark..."
                            if [ %(autodownload)i -eq 0 ]; then 
                                PATHPREFIX="/mnt/models/${MODEL}";
                            fi

                            /usr/local/bin/llama-bench -m ${PATHPREFIX}/*${QUANTIZATION}.gguf -p 0 -r %(repetitions)i -n %(length)i -o json > output.json
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
