# Llama Benchmarks

A set of experiments for evaluating LLM performance using SystemsLab. These
experiments are intended to run on machines with Nvidia GPUs.

## Prerequisites

`llama-bench` from `llama.cpp` is built and located in `/usr/local/bin`. The 
repo and build instructions can be found [here][llama.cpp]

*Note:* be sure you have CUDA toolkit already installed and build with the
options to enable CUDA acceleration.

One or more models in `GGUF` format is downloaded and located in `/mnt`. You can
download these models from Hugging Face. The Llama 2 7B model can be found
[here][Llama-2-7B-GGUF] You do not have to download all of the quantized models
but must have at least one.

## Parameters

* model - the name of the model to use, eg: `Llama-2-7B` note that we do not 
  provide the `-GGUF` suffix
* quantization - the quantization format eg: `Q4_K_M`
* powercap - specify a power limit to be applied to all Nvidia GPUs in the
  system. A powercap of `0` results in the default power limit for the card
  being used.
* repetitions - the number of test repetitions to run.
* length - the number of tokens to be generated.
* gpu - a gpu model for the experiments, used as a scheduling constraint and in
  the experiment name.

## Artifacts

* output.json - the JSON output of the llama-bench command which includes
  metrics about inference performance.
* metrics.json - the automatically collected Rezolus metrics which capture
  system-level performance data.

## Proposed Analysis Goals

* Measure the performance of several GPUs running inference on the same model.
* See how model size impacts inference speed.
* Evaluate how different quantization methods impact inference speed.
* Sweep the powercap of a GPU and see how token/s per watt changes.

[llama.cpp]: https://github.com/ggerganov/llama.cpp
[Llama-2-7B-GGUF]: https://huggingface.co/TheBloke/Llama-2-7B-GGUF
