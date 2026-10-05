#!/bin/sh
set -eu

SOURCE="./src/apt"
PUBLIC="./public/apt"
POOL="$PUBLIC/pool/main"
DIST_PREFIX="$PUBLIC/dists/stable/main/binary-"

mkdir -p "$POOL"

for pkg in "$SOURCE"/*; do
  if [ -d "$pkg" ]; then
    arch="${pkg##*_}"
    dist="$DIST_PREFIX$arch"
    mkdir -p "$dist"
    dpkg-deb --root-owner-group -b "$pkg" "$POOL"/
  fi
done

for arch_dir in "$DIST_PREFIX"*; do
  if [ -d "$arch_dir" ]; then
    arch="${arch_dir##*-}"
    dpkg-scanpackages --arch "$arch" "${POOL%/*}" >"$DIST_PREFIX$arch"/Packages
    gzip -9 -c "$DIST_PREFIX$arch/Packages" >"$DIST_PREFIX$arch/Packages.gz"
  fi
done
