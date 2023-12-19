#!/usr/bin/env bash

set -e

tag=$1

if [[ -z "$tag" ]]; then
  tag="sourcegraph/helix-p4d:latest"
fi

docker build -t ${tag} --platform linux/amd64 .
