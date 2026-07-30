#!/bin/bash

# Setup directories
mkdir -p "$P4ROOT"
mkdir -p "$P4DEPOTS"
mkdir -p "$P4CKP"

# Restore checkpoint if symlink latest exists
if [ -L "$P4CKP/latest" ]; then
    echo "[INFO] Restoring checkpoint..."
	restore.sh
	rm "$P4CKP/latest"
	echo "[INFO] Server restored"

	echo "[INFO] Configuring the server..."
	setup.sh
	echo "[INFO] Server configured, restart required"
	exit 0
fi

# Configure the server on a fresh install when no instance is registered
# Header of p4dctl list and the message when there is no instance are ouput to stderr.
if [ -z "$(p4dctl list 2>/dev/null)" ]; then
    echo "[INFO] No existing server configuration detected. Running setup..."
    setup.sh
fi

# Start the server
echo "[INFO] Starting Server..."
p4dctl start -t p4d "$P4NAME"

# Retrieving server information to be displayed in the logs
p4 login <<EOF
$P4PASSWD
EOF

echo "[INFO] Server [RUNNING] with the following configuration"
until p4 info -s 2> /dev/null; do sleep 1; done
