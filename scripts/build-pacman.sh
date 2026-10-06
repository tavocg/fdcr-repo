#!/bin/sh
# External programs required: makepkg and repo-add.
# Optional: gpg, required only when GPG_KEY_ID is set.

set -eu

: "${SOURCE:=./src/pacman}"
: "${PUBLIC:=./public/pacman}"
: "${GPG_KEY_ID:=}"
: "${MAKEPKG_CONF:=}"

# Run makepkg with the optional provided config and GPG signing.
run_makepkg() {
  if [ -n "$MAKEPKG_CONF" ]; then
    set -- --config "$MAKEPKG_CONF" "$@"
  fi
  if [ -n "$GPG_KEY_ID" ]; then
    makepkg "$@" --sign --key "$GPG_KEY_ID"
  else
    makepkg "$@"
  fi
}

# Build one PKGBUILD and copy its package files into $PUBLIC.
# Argument: path to a PKGBUILD file.
build_pacman_package() (
  pkgbuild="$1"
  pkg_dir="${pkgbuild%/*}"

  cd "$pkg_dir"
  run_makepkg --clean --force

  found_package=false
  for package_file in "$pkg_dir"/*.pkg.tar.zst; do
    [ -f "$package_file" ] || continue

    cp "$package_file" "$PUBLIC/"

    if [ -n "$GPG_KEY_ID" ]; then
      cp "$package_file.sig" "$PUBLIC/"
    else
      rm -f "$PUBLIC/${package_file##*/}.sig"
    fi

    found_package=true
  done

  if [ "$found_package" = false ]; then
    printf 'makepkg produced no Pacman packages for %s\n' "$pkgbuild" >&2
    return 1
  fi
)

# Build every versioned package recipe below $SOURCE.
# Returns nonzero if no PKGBUILD files are found or a build fails.
build_pacman_packages() (
  found_package=false

  for pkgbuild in "$SOURCE"/*/*/PKGBUILD; do
    [ -f "$pkgbuild" ] || continue
    found_package=true
    build_pacman_package "$pkgbuild"
  done

  if [ "$found_package" = false ]; then
    printf 'No versioned PKGBUILD files found under %s\n' "$SOURCE" >&2
    return 1
  fi
)

# Create and sign the repository database from all built packages.
gen_pacman_repository() {
  set -- "$PUBLIC"/*.pkg.tar.zst

  if [ ! -f "$1" ]; then
    printf 'No Pacman packages found in %s\n' "$PUBLIC" >&2
    return 1
  fi

  if [ -n "$GPG_KEY_ID" ]; then
    repo-add --sign --key "$GPG_KEY_ID" "$PUBLIC/fdcr.db.tar.gz" "$@"
  else
    rm -f "$PUBLIC/fdcr.db.tar.gz.sig" "$PUBLIC/fdcr.db.sig"
    repo-add "$PUBLIC/fdcr.db.tar.gz" "$@"
  fi
}

# Build all package versions and update the hosted repository. Sign packages and
# repository metadata when GPG_KEY_ID is set. Arguments are ignored.
main() {
  mkdir -p "$PUBLIC"
  build_pacman_packages
  gen_pacman_repository
}

main "$@"
