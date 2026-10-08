#!/bin/sh
set -eu

if [ "${1:-}" = --name ]; then
  printf '%s\n' 'firmador'
  exit 0
fi

. "$(dirname "$0")/../../scripts/package-build.sh"
prepare_nix_tree 'firmador-jammy-2.0.0-1' "$1" "$2" 'tree'
