#!/bin/sh
# External programs required: rpm, rpmbuild, createrepo_c, tar, cp, and mktemp.
# Optional: gpg, required only when GPG_KEY_ID is set.

if [ -r .env ]; then
  . ./.env
fi

set -eu

: "${SOURCE:=./src/centos-stream-9}"
: "${PUBLIC:=./public/centos-stream-9}"
: "${GPG_KEY_ID:=}"

# Build one RPM from a source package directory containing a .spec and rootfs/.
# Argument: package source directory. Copies built RPMs into $PUBLIC.
build_rpm_package() (
  pkg_dir="$1"
  spec_file=""

  for candidate in "$pkg_dir"/*.spec; do
    [ -f "$candidate" ] || continue

    if [ -n "$spec_file" ]; then
      printf 'More than one spec file found in %s\n' "$pkg_dir" >&2
      return 1
    fi

    spec_file="$candidate"
  done

  if [ -z "$spec_file" ] || [ ! -d "$pkg_dir/rootfs" ]; then
    printf 'Expected one .spec file and a rootfs/ directory in %s\n' "$pkg_dir" >&2
    return 1
  fi

  topdir="$(mktemp -d "${TMPDIR:-/tmp}/build-dnf.XXXXXX")"
  trap 'rm -rf "$topdir"' EXIT HUP INT TERM
  mkdir -p "$topdir/BUILD" "$topdir/BUILDROOT" "$topdir/RPMS" "$topdir/SOURCES" "$topdir/SPECS" "$topdir/SRPMS" "$topdir/rpmdb" "$topdir/tmp"
  tar -C "$pkg_dir/rootfs" -czf "$topdir/SOURCES/payload.tar.gz" .

  rpm --dbpath "$topdir/rpmdb" --initdb
  rpmbuild \
    --define "_topdir $topdir" \
    --define "_dbpath $topdir/rpmdb" \
    --define "_tmppath $topdir/tmp" \
    -bb "$spec_file"

  found_rpm=false
  for rpm_file in "$topdir"/RPMS/*/*.rpm; do
    [ -f "$rpm_file" ] || continue
    cp "$rpm_file" "$PUBLIC/"
    found_rpm=true
  done

  if [ "$found_rpm" = false ]; then
    printf 'rpmbuild produced no RPM for %s\n' "$pkg_dir" >&2
    return 1
  fi
)

# Build every RPM source package under $SOURCE.
# Returns nonzero if a build fails or no source packages are present.
build_rpm_packages() {
  found_package=false

  for pkg_dir in "$SOURCE"/*; do
    [ -d "$pkg_dir" ] || continue
    found_package=true
    build_rpm_package "$pkg_dir"
  done

  if [ "$found_package" = false ]; then
    printf 'No RPM source packages found in %s\n' "$SOURCE" >&2
    return 1
  fi
}

# Generate repository metadata and optionally sign repomd.xml.
# Uses createrepo_c; GPG_KEY_ID enables the detached metadata signature.
gen_rpm_repository() {
  createrepo_c --update "$PUBLIC"

  if [ -n "$GPG_KEY_ID" ]; then
    gpg --batch --yes --local-user "$GPG_KEY_ID" --armor --detach-sign \
      --output "$PUBLIC/repodata/repomd.xml.asc" \
      "$PUBLIC/repodata/repomd.xml"
  fi
}

# Build all RPMs from $SOURCE and update the repository in $PUBLIC.
# Arguments are ignored.
main() {
  mkdir -p "$PUBLIC"
  build_rpm_packages
  gen_rpm_repository
}

main "$@"
