#!/bin/sh
set -eu

if [ "${1:-}" = --name ]; then
  printf '%s\n' 'bccr-certs'
  exit 0
fi

. "$(dirname "$0")/../../scripts/package-build.sh"
prepare_nix_tree 'bccr-certs-fedora-2026.08-1' "$1" "$2" 'rootfs'
