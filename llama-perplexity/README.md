# Llama Benchmarks

A set of experiments for evaluating LLM performance using SystemsLab. These
experiments are intended to run on machines with Nvidia GPUs.

## Prerequisites

`perplexity` from `llama.cpp` is built and located at
`/usr/local/bin/llama-perplexity`. The repo and build instructions can be found
[here][llama.cpp]

When `AUTODOWNLOAD` is enabled, the `huggingface-cli` tool must be available in
the `PATH`.

*Note:* be sure you have CUDA toolkit already installed and build with the
options to enable CUDA acceleration.

## Model Downloads

This experiment assumes that we are measuring the performance of GGUF quantized
weights. You can download these models from Hugging Face. For example, the Llama
2 7B model can be found [here][Llama-2-7B-GGUF]. At this time we also assume
that the quantized models are provided by `TheBloke` or for OpenLlama by
`brayniac`.

There are two ways for model weights to be provided. One is to let the
experiment automatically download from HuggingFace. This is optimized for cloud
usage where ingress bandwidth is free and plentiful but disk space on the
runners has a significant impact on cost to run. For this mode, leave
`AUTODOWNLOAD` set to `1` in the run script. The experiment will automatically
fetch the quantized model weights for that run, and they will be deleted on
experiment completion.

For local runs of experiments, this is an inefficient approach. Disk space to
host the weights either on the runner or on an NFS mount is cheap, and bandwidth
is limited. In that case, it is expected that the weights for each model are
kept in `/mnt/models/${MODEL}`. The user is expected to pre-download all the
model weights they need using the `hugggingface-cli` tool.

## Parameters

* model - the name of the model to use, eg: `Llama-2-7B` note that we do not 
  provide the `-GGUF` suffix
* quantization - the quantization format eg: `Q4_K_M`
* powercap - specify a power limit to be applied to all Nvidia GPUs in the
  system. A powercap of `0` results in the default power limit for the card
  being used.
* context - the size of the prompt context
* gpu - a gpu model for the experiments, used as a scheduling constraint and in
  the experiment name.

## Artifacts

* output.json - the JSON output of the llama-bench command which includes
  metrics about inference performance.
* metrics.json - the automatically collected Rezolus metrics which capture
  system-level performance data.

## Proposed Analysis Goals

* Compare models to find which have better perplexity.
* See how model size impacts perplexity.
* Evaluate how different quantization methods impact perplexity.

[llama.cpp]: https://github.com/ggerganov/llama.cpp
[Llama-2-7B-GGUF]: https://huggingface.co/TheBloke/Llama-2-7B-GGUF
