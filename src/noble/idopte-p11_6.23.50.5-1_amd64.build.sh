#!/bin/sh
set -eu

if [ "${1:-}" = --name ]; then
  printf '%s\n' 'idopte-p11'
  exit 0
fi

. "$(dirname "$0")/../../scripts/package-build.sh"
prepare_nix_tree 'idopte-p11-noble' "$1" "$2" 'tree'
