local systemslab = import 'systemslab.libsonnet';

function(model='Llama-2-7B', quantization='Q4_K_M', powercap='0', gpu='rtx2080ti', context='512', autodownload='1')
    local args = {
        model: model,
        quantization: quantization,
        powercap: powercap,
        gpu: gpu,
        context: context,
        autodownload: autodownload,
    };
    local
        context = std.parseInt(args.context),
        powercap = std.parseInt(args.powercap),
        autodownload = std.parseInt(args.autodownload);
    {
        name: 'perplexity_%(model)s_%(quantization)s_ctx%(context)i' % {
            model: model,
            quantization: quantization,
            context: context,
        },
        jobs: {
            perplexity: {
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

                            echo "downloading test file..."
                            curl -O -L https://huggingface.co/datasets/ggml-org/ci/resolve/main/wikitext-2-raw-v1.zip
                            unzip wikitext-2-raw-v1.zip
                            ls -l wikitext-2-raw

                            if [ %(autodownload)i -eq 1 ]; then
                                echo "downloading model..."
                                huggingface-cli download ${HFUSER}/${MODEL} --local-dir . --local-dir-use-symlinks False --include="*${QUANTIZATION}.gguf"
                                ls -l *.gguf
                            fi

                            PATHPREFIX=".";

                            if [ %(autodownload)i -eq 0 ]; then 
                                PATHPREFIX="/mnt/models/${MODEL}";
                            fi

                            echo "running test..."
                            /usr/local/bin/llama-perplexity -m ${PATHPREFIX}/*${QUANTIZATION}.gguf -f ./wikitext-2-raw/wiki.test.raw --n-gpu-layers 99 -c %(context)i | tee output.log
                        ||| % {
                            model: model,
                            quantization: quantization,
                            powercap: powercap,
                            context: context,
                            autodownload: autodownload,
                        },
                        background=false
                    ),

                    // Upload the artifacts
                    systemslab.upload_artifact('output.log'),
                ],
            },
        },
    }
