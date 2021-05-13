Building firod
==============

This repository contains simplified build scripts for making firod that cache compiled code. To run, simply install
docker and do the following:

```shell
# Make the firo-build image from our Dockerfile.
docker build -t firo-build .

# `-v firo-build:/home/firo-builder/build` tells docker to keep around the contents of the build directory, which is
# needed for builds to be fast.
#
# `-v "$PWD/outputs":/home/firo-builder/outputs` connects the ~/outputs directory in the image to the outputs directory
# in the container.
repository=https://github.com/firoorg/firo.git # this can be changed to any git repository; caches between repositories are shared
branch=master # caches are kept separately for each branch, so you can change this whenever you need
configflags="--enable-debug --with-gui=no" # changing config flags will trigger a rebuild of firod code
docker run -v=firo-build:/home/firo-builder/build -v="$PWD/outputs":/home/firo-builder/outputs firo-build -windows,linux,mac $repository $branch $configflags
```

Then you'll find your firod builds in `outputs/`.