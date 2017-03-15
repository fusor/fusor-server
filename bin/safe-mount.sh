#!/bin/bash

# Mounts an NFS share with a predefined configuration (readonly, target, etc)
# that attempts to prevent things like whitespace.
#
# Usage:
#  safe-mount.sh 123 selfhosted www.example.com /nfs_share nfs
#  safe-mount.sh <deploy id> <unique suffix> <host> <share path> <share type>

regex_contains_spaces='[[:space:]]+'

if ! [[ "$1" =~ ^[0-9]+$ ]]; then
  echo "Bad deployment id format. Numeric chars only."
  exit 1
fi

if ! [[ "$2" =~ ^[a-z]+$ ]]; then
  echo "Bad unique suffix format. Lowercase alphabet chars only."
  exit 1
fi

if [[ "$3" =~ $regex_contains_spaces ]]; then
  echo "Bad hostname format. Spaces not allowed."
  exit 1
fi

if [[ "$4" =~ $regex_contains_spaces ]]; then
  echo "Bad NFS share format. Spaces not allowed."
  exit 1
fi

if [[ "$5" =~ $regex_contains_spaces ]]; then
  echo "Bad mount type format. Spaces not allowed."
  exit 1
fi

if [[ -z "$5" ]]; then
  type='nfs'
else
  type="$5"
fi

mount="/tmp/fusor-test-mount-$1-$2"
mkdir -p "$mount"
./safe-umount.sh $1 $2 2> /dev/null # attempt to unmount any existing mount
mount -r -t $type --target "$mount" --source "$3:$4"

if [[ $? -ne 0 ]]; then
  echo "Failed to mount $4 share"
  exit 1
else
  echo $mount
fi
