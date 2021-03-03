#!/bin/bash

## Find latest checkpoint
unset -v latest
for file in "$P4CKP"/"$JNL_PREFIX".ckp.*.gz; do
  [[ $file -nt $latest ]] && latest=$file
done

## If file exists update symlink
if [ "$latest" ]; then
  echo "Updating latest symlink to: $latest"
  ln -f -s "$latest" "$P4CKP/latest"
else
  echo "Error: Unable to find a checkpoint"
  exit 255
fi
