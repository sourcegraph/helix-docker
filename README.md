# helix-docker

This repository contains a collection of source files for building Docker images for Perforce Helix. It exists purely because there is no other working Docker solution in existence for Perforce Helix.

## helix-p4d

This directory contains the source files for building a Perforce Helix core server Docker image. The published Docker images are available as [`sourcegraph/helix-p4d` on Docker Hub](https://hub.docker.com/r/sourcegraph/helix-p4d).

### Build the docker image

The `helix-p4d/build.sh` script will build the docker image for you. If you don't provide a tag to the script it will tag the image as `sourcegraph/helix-p4d:latest`

```sh
./build.sh <tag>
```

### Usage

To have a disposable Perforce Helix core server running, simply run:

```sh
docker run --rm \
    --publish 1666:1666 \
    sourcegraph/helix-p4d:2023.1
```

The above command makes the server avaialable locally at port `1666`, with a default super user `admin` and its password `pass12349ers`.

All available options and their default values:

```sh
NAME=perforce-server
P4HOME=/p4
P4NAME=master
P4TCP=1666
P4PORT=1666
P4USER=admin
P4PASSWD=pass12349ers
P4CASE=-C0
P4CHARSET=utf8
JNL_PREFIX=perforce-server
```

Use the `--env` flag to override default options:

```sh
docker run --rm \
    --publish 1666:1666 \
    --env P4USER=amy \
    --env P4PASSWD=securepassword \
    sourcegraph/helix-p4d:2023.1
```

> [!WARNING]
> Please note that although the server survives over restarts (i.e. data is kept), it may break if you change the options after the initial bootstrap. This is because on the very first run options are getting hard-coded to the Perforce Helix Core server configuration.

To start a long-running production container, do remember to mount a volume to the data directory (`P4HOME`) and replace the `--rm` flag with `-d` (detach). For example:

```sh
docker run -d \
    --publish 1666:1666 \
    --env P4PASSWD=securepassword \
    --volume ~/.helix-p4d-home:/p4 \
    sourcegraph/helix-p4d:2023.1
```

Now that you have a running server, please read our handbook for [how to set up the client side](https://handbook.sourcegraph.com/departments/technical-success/support/process/p4-enablement/).

### Running Perforce Helix with SSL enabled

First generate a self-signed certificate:

```bash
mkdir ssl
pushd ssl
openssl genrsa -out privatekey.txt 2048
openssl req -new -key privatekey.txt -out certrequest.csr
openssl x509 -req -days 365 -in certrequest.csr -signkey privatekey.txt -out certificate.txt
rm certrequest.csr
popd
```

Then start the server with `P4SSLDIR` set to a directory containing the private key and certificate and set `P4PORT` to use SSL, like so:

```bash
docker run --rm \
    --publish 1666:1666 \
    --env P4PORT=ssl:1666 \
    --env P4SSLDIR=/ssl \
    --volume ./ssl:/ssl \
    sourcegraph/helix-p4d:2023.1
```

## Credits

This repository is heavily inspired by https://github.com/p4paul/helix-docker and https://github.com/ambakshi/docker-perforce.
