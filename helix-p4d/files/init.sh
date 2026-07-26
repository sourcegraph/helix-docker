#!/bin/bash

# Setup directories
mkdir -p "$P4ROOT"
mkdir -p "$P4DEPOTS"
mkdir -p "$P4CKP"

# Restore checkpoint if symlink latest exists
if [ -L "$P4CKP/latest" ]; then
    echo "Restoring checkpoint..."
	restore.sh
	rm "$P4CKP/latest"
fi

echo "Configuring the server..."
setup.sh

# Start the server
echo "Perforce Server starting..."
p4dctl start -t p4d "$P4NAME"

# Retrieving server information to be displayed in the logs
p4 login <<EOF
$P4PASSWD
EOF

echo "Perforce Server [RUNNING] with the following configuration"
until p4 info -s 2> /dev/null; do sleep 1; done
