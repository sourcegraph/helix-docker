# --------------------------------------------------------------------------------
# Docker configuration for P4D
# --------------------------------------------------------------------------------
# Ubuntu noble and 24.04 are the same, but noble is the codename for 24.04
FROM ubuntu:24.04

LABEL org.opencontainers.image.source="https://github.com/M3dinar/helix-docker"
LABEL org.opencontainers.image.description="Perforce Helix Core (p4d) server, packaged for Docker."
LABEL org.opencontainers.image.authors="M3dinar <M3dinar@users.noreply.github.com>"

RUN apt-get update && \
  apt-get install -y wget gnupg2

# --------------------------------------------------------------------------------
# Docker BUILD
# --------------------------------------------------------------------------------

# Create perforce user and install Perforce Server
# Do in-page search over https://package.perforce.com/apt/ubuntu/dists/noble/release/binary-amd64/Packages
# for "Package: helix-p4d"
# Update Ubuntu and add Perforce Package Source
RUN apt-get update && apt-get install -y wget gnupg && \
  wget -qO - https://package.perforce.com/perforce.pubkey | gpg --dearmor -o /etc/apt/keyrings/perforce.gpg && \
  echo "deb [signed-by=/etc/apt/keyrings/perforce.gpg] http://package.perforce.com/apt/ubuntu noble release" > /etc/apt/sources.list.d/perforce.list && \
  apt-get update && \
  apt-get install -y helix-p4d=2026.1-2972966~noble

RUN apt-get remove -y wget gnupg2 && \
  apt-get autoremove -y && \
  apt-get clean -y && \
  rm -rf /var/lib/apt/lists/*

# Add external files
COPY files/restore.sh /usr/local/bin/restore.sh
COPY files/setup.sh /usr/local/bin/setup.sh
COPY files/init.sh /usr/local/bin/init.sh

RUN \
  chmod +x /usr/local/bin/restore.sh && \
  chmod +x /usr/local/bin/setup.sh && \
  chmod +x /usr/local/bin/init.sh

# --------------------------------------------------------------------------------
# Docker ENVIRONMENT
# --------------------------------------------------------------------------------

# Default Environment
ARG P4NAME=perforce-server
ARG P4TCP=1666
ARG P4USER=admin
ARG P4PASSWD=pass12349ers
ARG P4CASE=-C0
ARG P4CHARSET=utf8

# Dynamic Environment
ENV P4NAME=$P4NAME \
  P4TCP=$P4TCP \
  P4PORT=$P4TCP \
  P4USER=$P4USER \
  P4PASSWD=$P4PASSWD \
  P4CASE=$P4CASE \
  P4CHARSET=$P4CHARSET \
  JNL_PREFIX=$P4NAME

# Base Environment
ENV P4HOME=/p4

# Derived Environment
ENV P4ROOT=$P4HOME/root \
  P4DEPOTS=$P4HOME/depots \
  P4CKP=$P4HOME/checkpoints

# Expose Perforce; TCP port and volumes
EXPOSE $P4TCP
VOLUME $P4HOME

# --------------------------------------------------------------------------------
# Docker RUN
# --------------------------------------------------------------------------------

ENTRYPOINT \
  init.sh && \
  /usr/bin/tail -F $P4HOME/logs/log

HEALTHCHECK \
  --interval=2m \
  --timeout=10s \
  CMD p4 info -s > /dev/null || exit 1
