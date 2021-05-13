#!/bin/bash
set -x # trace execution
set -e # exit on failure
set -o pipefail # exit on pipe failures
source make-deterministic.sh

if [[ "x$4" = "x" ]]; then
  echo "usage: $0 [--clean] --[windows][,linux][,mac] repository branch [configflags...]" >&2
  echo "arguments must be given in the order shown above" >&2
  exit 1
fi

if [[ "$1" = "--clean" ]]; then
  CLEAN=1
  shift
fi

if echo "$1" | grep -q windows; then
  BUILD_WINDOWS=1
fi
if echo "$1" | grep -q linux; then
  BUILD_LINUX=1
fi
if echo "$1" | grep -q mac; then
  BUILD_MAC=1
fi

shift

if [[ "$BUILD_WINDOWS" != 1 && "$BUILD_LINUX" != 1 && "$BUILD_MAC" != 1 ]]; then
  echo "usage: $0 -[windows][,linux][,mac] repository branch revision [configflags...]" >&2
  echo "error: you must build for at least one of windows, linux, or mac" >&2
  exit 1
fi

REPOSITORY="$1"
shift
BRANCH="$1"
shift
CONFIGFLAGS=(--prefix=/ "$@")

sanitize() {
  echo "${1//[^A-Za-z\.:]/_}"
}

build() {
  NUM_CPUS=$(nproc)
  HOST="$1"

  BUILD_DIR="build/$(sanitize "$BRANCH")/$HOST"

  if [[ "$CLEAN" = 1 ]]; then
    rm -rf "$BUILD_DIR"
  fi

  # Create the build directory, pull updates, and checkout the correct revision.
  if [[ ! -d "$BUILD_DIR" ]]; then
    git clone --branch "$BRANCH" "$REPOSITORY" "$BUILD_DIR"
    pushd "$BUILD_DIR"
  else
    pushd "$BUILD_DIR"
    git remote rm origin
    git remote add origin "$REPOSITORY"
    git fetch origin
    git checkout "origin/$BRANCH"
  fi

  if [[ ! -e ./configure ]]; then
    # We only need to build dependencies if we've never done so before.

    # Download Mac SDK if required
    if echo "$HOST" | grep -q darwin; then
      if [ ! -e "../../MacOSX10.11.sdk.tar.gz" ]; then
        wget -P ../.. "https://github.com/MZaf/MacOSX10.11.sdk/raw/master/MacOSX10.11.sdk.tar.gz"
      fi

      if [[ "$(sha256sum ../../MacOSX10.11.sdk.tar.gz | cut -d' ' -f1)" != "fc65dd34a3665a549cf2dc005c1d13fcead9ba17cadac6dfd0ebc46435729898" ]]; then
        rm "../../MacOSX10.11.sdk.tar.gz"
        echo "build failed due to incorrect checksum for build/MacOSX10.11.sdk.tar.gz" >&2
        exit 1
      fi

      if [[ ! -e depends/SDKs/MacOSX10.11.sdk ]]; then
        mkdir -p depends/SDKs
        tar -x -C depends/SDKs -f ../../MacOSX10.11.sdk.tar.gz
      fi
    fi

    # Make dependencies
    make -j$NUM_CPUS -C "$PWD/depends" HOST="$HOST"

    # Build our ./configure script. The presence of this script also determines if dependencies are built.
    ./autogen.sh
  fi

  if [[ ! -e Makefile || ! -e config.log || "$(sed -Ene '7s/^.*\.\/configure //p' config.log)" != "${CONFIGFLAGS[*]}" ]]; then
    CONFIG_SITE="$PWD/depends/$HOST/share/config.site" ./configure "${CONFIGFLAGS[@]}"
  fi

  # Build firod
  make -j$NUM_CPUS

  # Copy the files to the output directory.
  if [[ -e src/firod.exe ]]; then
    exe=".exe"
  else
    exe=""
  fi

  COMMIT="$(git log -1 --pretty="format:%h")"
  OUTDIR="$HOME/outputs/$COMMIT/$HOST"
  mkdir -p "$OUTDIR"
  cp src/{firod,firo-cli,firo-tx}$exe "$OUTDIR"
  if ! (echo "${CONFIGFLAGS[*]}" | grep -q with-gui=no); then
    cp src/qt/firo-qt$exe "$OUTDIR"
  fi

  popd
}

if [[ $BUILD_MAC = 1 ]]; then
  build x86_64-apple-darwin14
fi

if [[ $BUILD_WINDOWS = 1 ]]; then
  build x86_64-w64-mingw32
fi

if [[ $BUILD_LINUX = 1 ]]; then
  build x86_64-linux-gnu
fi