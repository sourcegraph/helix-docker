#!/bin/bash

## Test Checkpoint exists
if [ ! -L "$P4CKP/latest" ]; then
	echo "Error: Checkpoint for link $P4CKP/latest not found."
	exit 255
fi

## Check P4CASE environment variable
if [ -z "${P4CASE:-}" ]; then
	echo "Error: P4CASE environment variable is not set."
	exit 255
fi
if [ "${P4CASE:-}" != "-C0" ] && [ "${P4CASE:-}" != "-C1" ]; then
	echo "Error: P4CASE must be set to -C0 (Unix-style) or -C1 (Windows-style)."
	exit 255
fi

## Remove current data base
rm -rf $P4ROOT/*

## Set server name
echo $P4NAME > $P4ROOT/server.id

## Restore and Upgrade Checkpoint
echo "Restoring checkpoint..."
p4d $P4CASE -r $P4ROOT -jr -z $P4CKP/latest
p4d $P4CASE -r $P4ROOT -xu

## Set key environment variables
p4d $P4CASE -r $P4ROOT "-cset security=2"
