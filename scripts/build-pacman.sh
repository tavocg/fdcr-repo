#!/bin/sh
# External programs required: makepkg, repo-add, bsdtar, tar, sed, cp, and mktemp.
# Optional: gpg, required only when GPG_KEY_ID is set.

if [ -r .env ]; then
  . ./.env
fi

set -eu

. "$(dirname "$0")/package-build.sh"

: "${SOURCE:=./src/arch}"
: "${PUBLIC:=./public/arch}"
: "${GPG_KEY_ID:=}"
: "${MAKEPKG_CONF:=}"

# Run makepkg with the optional provided config and GPG signing.
run_makepkg() {
  set -- --nodeps "$@"

  if [ -n "$MAKEPKG_CONF" ]; then
    set -- --config "$MAKEPKG_CONF" "$@"
  fi

  if [ -n "$GPG_KEY_ID" ]; then
    makepkg "$@" "PKGDEST=$PUBLIC" --sign --key "$GPG_KEY_ID"
  else
    makepkg "$@" "PKGDEST=$PUBLIC"
  fi
}

# Build one PKGBUILD directly into $PUBLIC.
# Argument: path to a PKGBUILD file.
build_pacman_package() (
  pkgbuild="$1"
  pkg_dir="${pkgbuild%/*}"
  pkg_dir=$(CDPATH= cd "$pkg_dir" && pwd)

  staging_dir=$(mktemp -d "${TMPDIR:-/tmp}/build-pacman.XXXXXX")
  trap 'rm -rf "$staging_dir"' EXIT HUP INT TERM
  prepare_package_tree "$pkg_dir" "$staging_dir"
  cd "$staging_dir"
  run_makepkg --clean --force
)

# Build every versioned package recipe below $SOURCE.
# Returns nonzero if no PKGBUILD files are found or a build fails.
build_pacman_packages() (
  found_package=false

  for pkgbuild in "$SOURCE"/*/PKGBUILD; do
    [ -f "$pkgbuild" ] || continue
    found_package=true
    if skip_nix_package "${pkgbuild%/*}"; then
      remove_skipped_artifacts "${pkgbuild%/*}" pacman "$PUBLIC"
      continue
    fi
    build_pacman_package "$pkgbuild"
  done

  if [ "$found_package" = false ]; then
    printf 'No PKGBUILD files found under %s\n' "$SOURCE" >&2
    return 1
  fi
)

# Create and sign the repository database from all built packages.
gen_pacman_repository() {
  # repo-add updates an existing database, so recreate it to remove entries for
  # omitted packages, including old signatures and database backups.
  rm -f "$PUBLIC"/fdcr.db "$PUBLIC"/fdcr.db.* "$PUBLIC"/fdcr.files "$PUBLIC"/fdcr.files.*
  set --
  for package_file in "$PUBLIC"/*.pkg.tar.*; do
    [ -f "$package_file" ] || continue

    case "$package_file" in
    *.sig) continue ;;
    esac

    set -- "$@" "$package_file"
  done

  if [ "$#" -eq 0 ]; then
    for kind in db files; do
      tar -czf "$PUBLIC/fdcr.$kind.tar.gz" --files-from /dev/null
      ln -s "fdcr.$kind.tar.gz" "$PUBLIC/fdcr.$kind"
      if [ -n "$GPG_KEY_ID" ]; then
        gpg --batch --yes --local-user "$GPG_KEY_ID" --detach-sign \
          --output "$PUBLIC/fdcr.$kind.tar.gz.sig" "$PUBLIC/fdcr.$kind.tar.gz"
        ln -s "fdcr.$kind.tar.gz.sig" "$PUBLIC/fdcr.$kind.sig"
      fi
    done
    return 0
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
  PUBLIC=$(CDPATH= cd "$PUBLIC" && pwd)

  if [ -z "$GPG_KEY_ID" ]; then
    for signature_file in "$PUBLIC"/*.pkg.tar.*.sig; do
      [ -f "$signature_file" ] || continue
      rm -f "$signature_file"
    done
  fi

  build_pacman_packages
  gen_pacman_repository
}

main "$@"
