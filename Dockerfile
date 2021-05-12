# syntax=docker/dockerfile:1

FROM ubuntu:bionic

RUN apt-get update -y \
    && apt-get upgrade -y \
    && apt-get install -y \
        autoconf \
        automake \
        binutils-aarch64-linux-gnu \
        binutils-arm-linux-gnueabihf \
        binutils-gold \
        bsdmainutils \
        ca-certificates \
        cmake \
        curl \
        faketime \
        fonts-tuffy \
        g++ \
        g++-mingw-w64 \
        git \
        imagemagick \
        libbz2-dev \
        libcap-dev \
        librsvg2-bin \
        libtiff-tools \
        libtool \
        libz-dev \
        mingw-w64 \
        nsis \
        pkg-config \
        python \
        python-dev \
        python-setuptools \
        rename \
        wget \
        zip

RUN update-alternatives --set i686-w64-mingw32-gcc /usr/bin/i686-w64-mingw32-gcc-posix \
    && update-alternatives --set i686-w64-mingw32-g++ /usr/bin/i686-w64-mingw32-g++-posix \
    && update-alternatives --set x86_64-w64-mingw32-gcc /usr/bin/x86_64-w64-mingw32-gcc-posix \
    && update-alternatives --set x86_64-w64-mingw32-g++ /usr/bin/x86_64-w64-mingw32-g++-posix

RUN useradd -ms /bin/bash firo-builder \
    && mkdir /home/firo-builder/build /home/firo-builder/outputs \
    && chown firo-builder:firo-builder /home/firo-builder/build /home/firo-builder/outputs

COPY --chown=firo-builder:firo-builder make-deterministic.sh /home/firo-builder/
COPY --chown=firo-builder:firo-builder build.sh /home/firo-builder/

VOLUME /home/firo-builder/outputs
VOLUME /home/firo-builder/build
USER firo-builder:firo-builder
WORKDIR /home/firo-builder
ENTRYPOINT ["/home/firo-builder/build.sh"]
