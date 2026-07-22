#!/bin/bash

opts=()

# Check P4CHARSET environment variable
if [ -z "${P4CHARSET:-}" ]; then
    echo "Error: P4CHARSET environment variable is not set."
    exit 255
fi
if [ "${P4CHARSET:-}" != "none" && "${P4CHARSET:-}" != "utf8" ]; then
    echo "Error: P4CHARSET value unknown, expected 'none' or 'utf8'."
    exit 255
fi

# If P4CHARSET is set to "none", do not pass --unicode. Otherwise include it.
if [ "${P4CHARSET:-}" != "none" ]; then
    opts+=(--unicode)
fi

# Run the container and get a terminal into it so you can cat the file to get the list of option (No known web documentation)
/opt/perforce/sbin/configure-helix-p4d.sh "$P4NAME" -n -p "$P4PORT" -r "$P4HOME" -u "$P4USER" -P "${P4PASSWD}" --case="$P4CASE" "${opts[@]}"

p4 configure set $P4NAME#server.depot.root=$P4DEPOTS
p4 configure set $P4NAME#journalPrefix=$P4CKP/$JNL_PREFIX

# Stopping the server so the previous configuration are taken into account
p4dctl stop -t p4d "$P4NAME"