#!/bin/bash

opts=()

# Check P4CHARSET environment variable
if [ -z "${P4CHARSET:-}" ]; then
    echo "[ERROR] P4CHARSET environment variable is not set."
    exit 255
fi
if [ "${P4CHARSET:-}" != "none" ] && [ "${P4CHARSET:-}" != "utf8" ]; then
    echo "[ERROR] P4CHARSET value unknown, expected 'none' or 'utf8'."
    exit 255
fi

# If P4CHARSET is set to "none", do not pass --unicode. Otherwise include it.
if [ "${P4CHARSET:-}" != "none" ]; then
    opts+=(--unicode)
fi

## Check P4CASE environment variable
if [ -z "${P4CASE:-}" ]; then
	echo "[ERROR] P4CASE environment variable is not set."
	exit 255
fi
if [ "${P4CASE:-}" != "-C0" ] && [ "${P4CASE:-}" != "-C1" ]; then
	echo "[ERROR] P4CASE must be set to -C0 (Unix-style) or -C1 (Windows-style)."
	exit 255
fi
if [ "${P4CASE:-}" == "-C1" ]; then
    opts+=(--case=1)
else
    opts+=(--case=0)
fi

# Script to configure the server with the given param so a p4dctl is created.
# Helper of the script available in it
#-------------------------------------------------------------------------------
# Configuration script for P4 Server
# Copyright 2025, Perforce Software Inc. All rights reserved.
#
# Synopsis:
#
#    configure-p4d.sh [service-name] [options]
#
#    Where options are:
#
#    -n                     - Use the following flags in non-interactive mode
#    -p <P4PORT>            - Set P4 Server's address
#    -r <P4ROOT>            - Set P4 Server's root directory
#    -u <username>          - P4 super-user login name
#    -P <password>          - P4 super-user password
#    --unicode              - Enable unicode mode on server
#    --case                 - Case-sensitivity (0=sensitive[default],1=insensitive)
#
#    Password is only needed on initial configuration when the super-user
#    account is created. If reconfiguring an existing Perforce Server, the
#    super-user name and password are left alone.
#
#    Unicode mode is disabled by default. Specify --unicode if you 
#    want it. This will change in a future release.
#
#-------------------------------------------------------------------------------
/opt/perforce/sbin/configure-helix-p4d.sh "$P4NAME" -n -p "$P4PORT" -r "$P4HOME" -u "$P4USER" -P "${P4PASSWD}" "${opts[@]}"

echo "[INFO] Configuring server settings..."
p4 configure set $P4NAME#server.depot.root=$P4DEPOTS
p4 configure set $P4NAME#journalPrefix=$P4CKP/$JNL_PREFIX

# Stopping the server so the previous configuration are taken into account
p4dctl stop -t p4d "$P4NAME"