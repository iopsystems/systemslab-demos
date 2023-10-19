# build rezolus
The build_install_rezolus.jsonnet builds a Rezolus repo and installs the binary on the target host at the target path.
* --param repo: the Rezolus repo, default "https://github.com/iopsystems/rezolus.git"
* --param branch: the branch, default "main"
* --param host: the target machine if given
* --param target: the target binary path if given
```
systemslab submit build_install_rezolus.jsonnet --param target=$INSTALL_PATH --param host=$TARGET_HOST
```
# profile rezolus
The profile-rezolus.jsonnet uses the perf to profile the CPU usage of Rezolus.
* --param host: the target machine if given
* --param rezolus: the Rezolus binary, default "rezolus"
* --param perf: the Perf binary, default "perf"
```
systemslab submit --wait  ./profile-rezolus.jsonnet  --param "rezolus=$REZOLUS_BINARY_PATH" --param "perf=$PERF_BINARY_PATH" --param "host=$TARGET_HOT
```