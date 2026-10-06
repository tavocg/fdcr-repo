#!/bin/sh
set -eu

# External programs required: dpkg-deb, dpkg-scanpackages, gzip, apt-ftparchive.
# Optional: gpg, required only when GPG_KEY_ID is set.

: "${ORIGIN:=Soporte Firma Digital}"
: "${LABEL:=Repositorio APT de Soporte Firma Digital}"
: "${SUITE:=stable}"
: "${CODENAME:=stable}"
: "${COMPONENT:=main}"
: "${DESCRIPTION:=Repositorio oficial de paquetes de Soporte Firma Digital}"
: "${SOURCE:=./src/apt}"
: "${PUBLIC:=./public/apt}"

# Optional.
# Example:
#   GPG_KEY_ID="ABCDEF1234567890" ./build-apt.sh
: "${GPG_KEY_ID:=}"

POOL="$PUBLIC/pool/$COMPONENT"            # ./public/apt/pool/main
DIST="$PUBLIC/dists/$CODENAME/$COMPONENT" # ./public/apt/dists/stable/main

# Build one Debian package from a directory containing its package tree.
# Argument: package directory (for example, /path/to/firmador_1.0.0_amd64).
# Output: writes the .deb file into $POOL; returns nonzero on failure.
build_deb_package() {
  pkg_dir="$1"

  if ! [ -d "$pkg_dir" ]; then
    return 1
  fi

  dpkg-deb --root-owner-group --build "$pkg_dir" "$POOL" >&2
}

# Print a whitespace-separated list with $2 appended only if it is not present.
# Arguments: existing list and value to append. Output: updated list on stdout.
append_once() {
  arr="$1"
  val="$2"

  case " $arr " in
  *" $val "*) ;;
  *)
    if [ -z "$arr" ]; then
      arr="$val"
    else
      arr="$arr $val"
    fi
    ;;
  esac

  printf '%s\n' "$arr"
}

# Build every package directory under $SOURCE and collect its architecture.
# Output: unique, whitespace-separated architecture names on stdout.
# Returns nonzero if a package build fails or no package directories exist.
build_deb_packages() {
  arches=""
  found_package=false

  for pkg_dir in "$SOURCE"/*; do
    [ -d "$pkg_dir" ] || continue
    found_package=true
    build_deb_package "$pkg_dir" || return "$?"
    arch="${pkg_dir##*/}"
    arch="${arch##*_}"
    arches="$(append_once "$arches" "$arch")"
  done

  if [ "$found_package" = false ]; then
    printf 'No package directories found in %s\n' "$SOURCE" >&2
    return 1
  fi

  printf '%s' "$arches"
}

# Generate Packages and Packages.gz for one architecture.
# Argument: architecture name. Writes the indexes below $DIST.
gen_arch_index() {
  arch="$1"

  dist_abs="$DIST/binary-$arch" # ./public/apt/dists/stable/main/binary-amd64
  mkdir -p "$dist_abs"

  pool="pool/$COMPONENT"
  dist_index="${DIST#"$PUBLIC"/}/binary-$arch/Packages"

  (
    set -e
    cd "$PUBLIC"
    dpkg-scanpackages --arch "$arch" "$pool" >"$dist_index"
    gzip -9 -c "$dist_index" >"$dist_index.gz"
  )
}

# Generate package indexes for each architecture argument.
# Arguments: one or more architecture names.
gen_arch_indexes() {
  for arch in "$@"; do
    gen_arch_index "$arch"
  done
}

# Write the repository Release metadata using the supplied architectures.
# Arguments: one or more architecture names. Writes $DIST/Release.
gen_release() {
  arches="$*"

  apt-ftparchive \
    -o "APT::FTPArchive::Release::Origin=$ORIGIN" \
    -o "APT::FTPArchive::Release::Label=$LABEL" \
    -o "APT::FTPArchive::Release::Suite=$SUITE" \
    -o "APT::FTPArchive::Release::Codename=$CODENAME" \
    -o "APT::FTPArchive::Release::Architectures=$arches" \
    -o "APT::FTPArchive::Release::Components=$COMPONENT" \
    -o "APT::FTPArchive::Release::Description=$DESCRIPTION" \
    release "$DIST" \
    >"$DIST/Release"
}

# Sign $DIST/Release as InRelease and Release.gpg using $GPG_KEY_ID.
# Returns nonzero when no key is configured or signing fails.
sign_release() {
  if [ -z "$GPG_KEY_ID" ]; then
    return 1
  fi

  dist="${DIST%"$COMPONENT"}"
  rm -f "$dist/InRelease" "$dist/Release.gpg"

  # Clearsigned Release file.
  # Modern APT clients normally prefer InRelease.
  gpg \
    --batch \
    --yes \
    --local-user "$GPG_KEY_ID" \
    --clearsign \
    --output "$dist/InRelease" \
    "$dist/Release"

  # Detached signature for compatibility.
  gpg \
    --batch \
    --yes \
    --local-user "$GPG_KEY_ID" \
    --armor \
    --detach-sign \
    --output "$dist/Release.gpg" \
    "$dist/Release"
}

# Build apt repository.
# Creates public/apt/ folder by default with the required structure for hosting.
main() {
  mkdir -p "$POOL" "$DIST"

  arches="$(build_deb_packages)"
  set -- $arches
  gen_arch_indexes "$@"
  gen_release "$@"

  if [ -n "$GPG_KEY_ID" ]; then
    sign_release
  fi
}

main "$@"
