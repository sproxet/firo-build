Building firod
==============

This repository contains simplified build scripts for making firod that cache compiled code. To run, simply install
docker and do the following:

```shell
# Make the firo-build image from our Dockerfile.
docker build -t firo-build .
docker run -v=firo-build:/build -v="$PWD/outputs":/build/outputs firo-build -windows,linux,mac https://github.com/firoorg/firo.git master --with-gui=no --enable-glibc-reduce-exports
```

Then you'll find your firod builds in `outputs/`.
