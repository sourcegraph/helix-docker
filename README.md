# helix-docker

This repository contains a collection of source files for building Docker images for Perforce Helix. It exists purely because there is no working Docker solution in existence for Perforce Helix.

## helix-p4d

This directory contains the source files for building a Perforce Helix core server Docker image. The published Docker images are available as [`ghcr.io/m3dinar/helix-p4d` on the GitHub Container Registry](https://github.com/M3dinar/helix-docker/pkgs/container/helix-p4d).

### Available tags

Every release publishes three tags:

- `latest` — always the most recently published image
- `<year>.<release>` (e.g. `2026.1`) — always the most recent build for that Perforce release, regardless of the underlying build number
- `<year>.<release>-<build>-r<N>` (e.g. `2026.1-2972966-r2`) — the exact, immutable version. `<year>.<release>-<build>` is the Perforce package version pinned in [`helix-p4d/Dockerfile`](helix-p4d/Dockerfile); `rN` is incremented every time the image is rebuilt and republished for that same Perforce version (e.g. following a fix unrelated to the Perforce version itself). Each `rN` corresponds to a dedicated, never-moved git tag of the same name, so the exact commit an image was built from can always be found with:

  ```sh
  git show <year>.<release>-<build>-rN
  ```

```sh
docker pull ghcr.io/m3dinar/helix-p4d:latest
```

### Default server configuration

- `security` : 2 instead of 4
- `server.depots.root` : `P4DEPOTS`
- `journalPrefix` : `P4CKP/JNL_PREFIX`

### Build the docker image

The `helix-p4d/build.sh` script will build the docker image for you. If you don't provide a tag to the script it will tag the image as `ghcr.io/m3dinar/helix-p4d:latest`

```
./build.sh <tag>
```

### Usage

To have a disposable Perforce Helix core server running, simply do:

```sh
docker run --rm \
    --publish 1666:1666 \
    ghcr.io/m3dinar/helix-p4d:latest
```

The above command makes the server avaialble locally at `:1666`, with a default super user `admin` and its password `pass12349ers`.

#### Environment variables
All available options and their default values:

```sh
P4HOME=/p4
P4NAME=perforce-server
P4TCP=1666
P4PORT=1666
P4USER=admin
P4PASSWD=pass12349ers
P4CASE=-C0
P4CHARSET=utf8
```

Use the `--env` flag to override default:

```sh
docker run --rm \
    --publish 1666:1666 \
    --env P4USER=amy \
    --env P4PASSWD=securepassword \
    ghcr.io/m3dinar/helix-p4d:latest
```

> [!WARNING]
> Please be noted that although the server survives over restarts (i.e. data are kept), but it may break if you change the options after the initial bootstrap (i.e. the very first run of the image, at when options are getting hard-coded to the Perforce Helix core server own configuration).

`P4CASE` : `-C0` means Unix-style and `-C1` Windows-style (only these 2 values are valid)
`P4CHARSET` : `none` and `utf8` are the only valid values
`JNL_PREFIX` : prefix for the perforce journal file

#### Volumes
To start a long-running production container, do remember to volume the data directory (`P4HOME`) and replace the `--rm` flag with `-d` (detach):

```sh
docker run -d \
    --publish 1666:1666 \
    --env P4PASSWD=securepassword \
    --volume ~/.helix-p4d-home:/p4 \
    ghcr.io/m3dinar/helix-p4d:latest
```

Now you have a running server, you can set up a Perforce client (`p4`/`p4v`) pointed at `<host>:1666` using the credentials above.

### Running Perforce Helix with SSL enabled

Frist, generate some self-signed SSL certificates:

```bash
mkdir ssl
pushd ssl
openssl genrsa -out privatekey.txt 2048
openssl req -new -key privatekey.txt -out certrequest.csr
openssl x509 -req -days 365 -in certrequest.csr -signkey privatekey.txt -out certificate.txt
rm certrequest.csr
popd
```

Next, we need to run the server with `P4SSLDIR` set to a directory containing the SSL files, and set `P4PORT` to use SSL:

```bash
docker run --rm \
    --publish 1666:1666 \
    --env P4PORT=ssl:1666 \
    --env P4SSLDIR=/ssl \
    --volume ./ssl:/ssl \
    ghcr.io/m3dinar/helix-p4d:2026.1
```

### Restore from a checkpoint
With a journal and checkpoint, generate a gz file
Put them in the folder `/p4/checkpoints/` (`$P4CKP`)
Create a simlink to the gz file named latest in the folder `$P4CKP`
Run the container, it will generate the DB from the checkpoint and remove the sym link. The gz can be removed once you're good with it.
Triggers are removed.

## CI / Release process

This repository uses GitHub Actions for three things:

- **Build check on pull requests** (`.github/workflows/docker-build-check.yml`): every PR targeting `main` builds the `helix-p4d` image (without pushing it). Merging is blocked on `main` if the build fails.
- **Weekly Perforce version check** (`.github/workflows/check-p4d-version.yml`): every Sunday, compares the `helix-p4d` version pinned in the Dockerfile against the latest one available from Perforce. If a newer version exists, it opens (or updates) a tracking issue labeled `p4d-update`.
- **Release** (`.github/workflows/create-release-tag.yml` + `.github/workflows/release.yml`): publishing a new image is a two-step, manually-triggered process:
  1. Run the **"Create Release Tag"** workflow (`Actions` tab → select it → `Run workflow`). It reads the version currently pinned in the Dockerfile on `main`, works out the next available release number, and pushes an immutable git tag `<year>.<release>-<build>-r<N>` (e.g. `2026.1-2972966-r2`) on the current `main` commit.
  2. That tag push automatically triggers the **"Release Docker Image"** workflow, which builds and publishes the image to GHCR under three tags: the full tag, `latest`, and `<year>.<release>`.

Because every `rN` is its own dedicated git tag that never moves, the exact commit an image was built from can always be found with `git show <tag>`.

## Credits

This repository is heavily inspired by https://github.com/p4paul/helix-docker and https://github.com/ambakshi/docker-perforce

## Fork

The fork was done to allow some changes
- Update of the dependancies
  - Ubuntu focal to noble (no support for racoon ATM)
  - Helix perforce to 2026.1
- Removed helix swarm
- Changed the whole restore checkpoint logic
- Improvements
  - Unified folder name
  - Unified the use of the setup in each case to configure and start the server
  - Use of p4dctl
- Fixes
 - Charset when there is no one selected