#!/bin/bash

set -e

build:init() {
  echo "build:init cleaning up old work directory: $WORKDIR"
  rm -rf $WORKDIR
    echo "build:init creating new work directory: $WORKDIR"
  mkdir -p $WORKDIR
  cp required runlevel make-slim $WORKDIR
}

build:mkDockerfile() {
  echo "build:mkDockerfile arch: $arch and $1"
  sed -e "s;^FROM BASE_IMG;FROM ${BASE_IMG}:${arch}-${DIST};" "Dockerfile.template" > $WORKDIR/Dockerfile.$arch
}

build:mkPreImg() {
  echo "build:mkPreImg PREFIX:$PREFIX ARCH:$arch"
  docker build -t $PREFIX-pre:$arch-latest $WORKDIR -f $WORKDIR/Dockerfile.$arch
}

build:mkFlatImg() {
  echo "build:mkFlatImg PREFIX:$PREFIX"
  id=$(docker create $PREFIX-pre:$arch-latest true)
  docker export $id > $WORKDIR/$id.tar
  cat $WORKDIR/$id.tar | docker import - thenatureofsoftware/ubuntu-$arch:$DIST
  rm $WORKDIR/$id.tar
  docker rm $id
  docker rmi -f $PREFIX-pre:$arch-latest
}

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORKDIR=${WORKDIR:-$BASEDIR/.work}

BASE_IMG=multiarch/ubuntu-core
DIST=xenial
TAG=16.04
ARCH=arm64
PREFIX=thenatureofsoftware/ubuntu-$ARCH

for arch in armhf arm64; do
  echo "building image for $arch"
  build:init
  build:mkDockerfile
  build:mkPreImg
  build:mkFlatImg
done
