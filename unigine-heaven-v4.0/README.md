# Unigine Heaven v4.0 Benchmark

***DO NOT PUBLISH!!!***

A set of experiments using Unigine's Heaven v4.0 Benchmark

## Prerequisites

`heaven.tgz` is placed in `/usr/local/share`. (Ask Brian for this)

Xorg / Nvidia Drivers / ... installed and configured. (Ask Brian for details)

## Parameters

See bash script

## Artifacts

* logs.json - CLI output from the benchmark
* results/frames.log - the framerate log from the benchmark.
* metrics.json - the automatically collected Rezolus metrics which capture
  system-level performance data.

## Proposed Analysis Goals

* Measure the performance of several GPUs.
* See how quality settings impact FPS.
* Sweep the powercap of a GPU and see how performance changes.
