#!/bin/bash

# Unmounts an NFS share with at predefined target
# that attempts to prevent things like unmounting other FSes
#
# Usage:
#  safe-umount.sh 123 selfhosted
#  safe-umount.sh <deploy id> <unique suffix>

if ! [[ "$1" =~ ^[0-9]+$ ]]; then
  echo "Bad deployment id."
  exit 1
fi

if ! [[ "$2" =~ ^[a-z]+$ ]]; then
  echo "Bad unique suffix format. Lowercase alphabet chars only."
  exit 1
fi

mount="/tmp/fusor-test-mount-$1-$2"

umount $mount 2> /dev/null
