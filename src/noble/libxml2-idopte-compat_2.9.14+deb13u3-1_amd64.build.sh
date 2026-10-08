#!/bin/sh
set -eu

if [ "${1:-}" = --name ]; then
  printf '%s\n' 'libxml2-idopte-compat'
  exit 0
fi

. "$(dirname "$0")/../../scripts/package-build.sh"
prepare_nix_tree 'libxml2-idopte-compat-noble' "$1" "$2" 'tree'
