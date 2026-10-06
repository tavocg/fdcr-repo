#!/bin/sh
set -eu

# Requires makepkg, repo-add, and a GPG signing key.
: "${SOURCE:=./src/pacman}"
: "${PUBLIC:=./public/pacman}"
: "${GPG_KEY_ID:?Set GPG_KEY_ID to the key used to sign packages and repository metadata}"

# Build and sign one PKGBUILD, then copy its package files into $PUBLIC.
# Argument: path to a PKGBUILD file.
build_pacman_package() (
  pkgbuild="$1"
  pkg_dir="${pkgbuild%/*}"

  (
    cd "$pkg_dir"
    makepkg --clean --force --sign --key "$GPG_KEY_ID"
  )

  found_package=false
  for package_file in "$pkg_dir"/*.pkg.tar.zst; do
    [ -f "$package_file" ] || continue
    cp "$package_file" "$PUBLIC/"
    cp "$package_file.sig" "$PUBLIC/"
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
  repo-add --sign --key "$GPG_KEY_ID" "$PUBLIC/fdcr.db.tar.gz" "$@"
}

# Build and sign all package versions, then update the hosted repository.
# Arguments are ignored. Run as a regular user with the GPG key available.
main() {
  mkdir -p "$PUBLIC"
  build_pacman_packages
  gen_pacman_repository
}

main "$@"
