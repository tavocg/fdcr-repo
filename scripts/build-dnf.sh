#!/bin/sh
# External programs required: rpm, rpmbuild, createrepo_c, tar, cp, and mktemp.
# Optional: gpg, rpmsign, and rpmkeys, required when GPG_KEY_ID is set.

if [ -r .env ]; then
  . ./.env
fi

set -eu

. "$(dirname "$0")/package-build.sh"

: "${SOURCE:=./src/fedora}"
: "${PUBLIC:=./public/fedora}"
: "${GPG_KEY_ID:=}"

# Build one RPM from a source package directory containing a .spec and rootfs/.
# Argument: package source directory. Copies built RPMs into $PUBLIC.
build_rpm_package() (
  pkg_dir="$1"
  topdir="$(mktemp -d "${TMPDIR:-/tmp}/build-dnf.XXXXXX")"
  trap 'rm -rf "$topdir"' EXIT HUP INT TERM
  mkdir -p "$topdir/package"
  prepare_package_tree "$pkg_dir" "$topdir/package"
  pkg_dir="$topdir/package"
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
    if skip_nix_package "$pkg_dir"; then
      remove_skipped_artifacts "$pkg_dir" rpm "$PUBLIC"
      continue
    fi
    build_rpm_package "$pkg_dir"
  done

  if [ "$found_package" = false ]; then
    printf 'No RPM source packages found in %s\n' "$SOURCE" >&2
    return 1
  fi
}

# Sign and verify every RPM being published, including any retained packages.
# Use a temporary RPM database containing only the configured public key.
sign_rpm_packages() (
  [ -n "$GPG_KEY_ID" ] || return 0

  signing_dir="$(mktemp -d "${TMPDIR:-/tmp}/sign-dnf.XXXXXX")"
  trap 'rm -rf "$signing_dir"' EXIT HUP INT TERM
  gpg --batch --yes --armor --output "$signing_dir/key.asc" --export "$GPG_KEY_ID"
  rpmkeys --dbpath "$signing_dir/rpmdb" --import "$signing_dir/key.asc"

  for rpm_file in "$PUBLIC"/*.rpm; do
    [ -f "$rpm_file" ] || continue
    rpmsign --define "_gpg_name $GPG_KEY_ID" \
      --define "__gpg $(command -v gpg)" \
      --define "_gpg_digest_algo sha256" \
      --define "_gpg_sign_cmd_extra_args --batch --no-tty --pinentry-mode error" \
      --addsign "$rpm_file"
    LC_ALL=C rpmkeys --dbpath "$signing_dir/rpmdb" --checksig --verbose \
      "$rpm_file" > "$signing_dir/verification.txt"
    cat "$signing_dir/verification.txt"
    # A successful checksum check alone also accepts unsigned RPMs.
    verified_signature=false
    while IFS= read -r verification_line; do
      case "$verification_line" in
        *Signature*': OK') verified_signature=true ;;
      esac
    done < "$signing_dir/verification.txt"
    if [ "$verified_signature" = false ]; then
      printf 'No verified RPM signature for %s\n' "$rpm_file" >&2
      return 1
    fi
  done
)

# Generate repository metadata and optionally sign repomd.xml.
# Uses createrepo_c; GPG_KEY_ID enables the detached metadata signature.
gen_rpm_repository() {
  createrepo_c --update "$PUBLIC"

  if [ -n "$GPG_KEY_ID" ]; then
    gpg --batch --yes --local-user "$GPG_KEY_ID" --armor --detach-sign \
      --output "$PUBLIC/repodata/repomd.xml.asc" \
      "$PUBLIC/repodata/repomd.xml"
  else
    rm -f "$PUBLIC/repodata/repomd.xml.asc"
  fi
}

# Build all RPMs from $SOURCE and update the repository in $PUBLIC.
# Arguments are ignored.
main() {
  mkdir -p "$PUBLIC"
  build_rpm_packages
  sign_rpm_packages
  gen_rpm_repository
}

main "$@"
