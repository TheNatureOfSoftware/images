#!/bin/bash

set -e

installgo() {
  mkdir -p $WORKDIR/usr/local
  wget "https://storage.googleapis.com/golang/go${GOVERSION}.${GOOS}-amd64.tar.gz" -O "${WORKDIR}/go${GOVERSION}.tar.gz"
  tar -C $WORKDIR/usr/local -xzf "${WORKDIR}/go${GOVERSION}.tar.gz"
}

clonehelm() {
  git clone https://github.com/kubernetes/helm $GOWORKDIR
  cd $GOWORKDIR
  git checkout "${HELMVERSION}"
  cd $BASEDIR
}

buildtiller() {
  cd $GOWORKDIR
  go get -u github.com/Masterminds/glide
  go get -u github.com/mitchellh/gox
  glide install --strip-vendor
  go build -o bin/protoc-gen-go ./vendor/github.com/golang/protobuf/protoc-gen-go

  BINDIR=$WORKDIR/rootfs
  GOFLAGS="-a -installsuffix cgo"
  TAGS=$HELMVERSION
  LDFLAGS=''

  GOOS=linux GOARCH=arm64 CGO_ENABLED=0 $GO build -o $BINDIR/tiller $GOFLAGS -tags $TAGS k8s.io/helm/cmd/tiller
  cd $BASEDIR
}

buildimg() {
  cp Dockerfile.arm64 $WORKDIR/rootfs
  docker build -t thenatureofsoftware/tiller-arm64:$HELMVERSION -f $WORKDIR/rootfs/Dockerfile.arm64 $WORKDIR/rootfs
}

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORKDIR=${WORKDIR:-$BASEDIR/.work}
GOVERSION="1.7.4"
#GOOS="darwin"
GOOS=linux
GOPATH="${WORKDIR}/.go_workspace"
PATH=$WORKDIR/usr/local/go/bin:$GOPATH/bin:$PATH
GOWORKDIR="${GOPATH}/src/k8s.io/helm"
PROJECT_NAME="kubernetes-helm"
HELMVERSION=v2.2.3
GO=go

if [ ! -d $WORKDIR/usr/local ]; then
  installgo
fi

if [ ! -d $GOWORKDIR ]; then
  clonehelm
fi

buildtiller
buildimg
