#!/bin/sh
# Shared by repository builders and adjacent <package>.build.sh hooks.

: "${SKIP_NIX:=0}"
: "${NIX_FLAKE:=.}"
case "$SKIP_NIX" in
  0|1) ;;
  *) printf 'SKIP_NIX must be 0 or 1\n' >&2; exit 1 ;;
esac
export NIX_FLAKE SKIP_NIX

skip_nix_package() {
  [ "$SKIP_NIX" = 1 ] && [ -f "$1.build.sh" ]
}

# Arguments: flake attribute, original source, empty destination, tree|rootfs.
# A generated payload replaces stale local generated files, never overlays them.
prepare_nix_tree() (
  set -eu
  attribute=$1 source_dir=$2 destination=$3 layout=$4
  output=$(nix build --no-link --print-out-paths "$NIX_FLAKE#$attribute")
  [ -d "$output" ] || { printf 'Expected one Nix output for %s\n' "$attribute" >&2; exit 1; }
  case "$layout" in
    tree) cp -R --preserve=mode,timestamps "$output/." "$destination/" ;;
    rootfs)
      # Keep package recipes and install scripts, but not an old payload or
      # makepkg work directories. Generated files come exclusively from Nix.
      for recipe in "$source_dir"/*.spec "$source_dir"/PKGBUILD "$source_dir"/*.install; do
        [ -f "$recipe" ] || continue
        cp -p "$recipe" "$destination/"
      done
      cp -R --preserve=mode,timestamps "$output/rootfs" "$destination/"
      ;;
    *) printf 'Unknown Nix payload layout: %s\n' "$layout" >&2; exit 1 ;;
  esac
  chmod -R u+w "$destination"
)

# Hooks receive absolute source/destination paths and must fail on any error.
prepare_package_tree() (
  set -eu
  source_dir=$(CDPATH= cd "$1" && pwd)
  destination=$(CDPATH= cd "$2" && pwd)
  if [ -f "$source_dir.build.sh" ]; then
    sh "$source_dir.build.sh" "$source_dir" "$destination"
  else
    cp -a "$source_dir/." "$destination/"
  fi
)

# Remove all prior versions of an omitted package, matching archive metadata
# rather than filename prefixes (which could also match another package).
remove_skipped_artifacts() (
  set -eu
  source_dir=$1 format=$2 repository=$3
  package_name=$(sh "$source_dir.build.sh" --name)
  [ -n "$package_name" ] || exit 1
  printf 'SKIP_NIX=1: omitting %s\n' "$package_name" >&2
  case "$format" in
    deb) set -- "$repository"/*.deb ;;
    rpm) set -- "$repository"/*.rpm ;;
    pacman) set -- "$repository"/*.pkg.tar.* ;;
  esac
  for artifact do
    [ -f "$artifact" ] || continue
    case "$artifact" in *.sig) continue ;; esac
    case "$format" in
      deb) name=$(dpkg-deb -f "$artifact" Package) ;;
      rpm) name=$(rpm -qp --queryformat '%{NAME}' "$artifact") ;;
      pacman)
        info=$(bsdtar -xOf "$artifact" .PKGINFO)
        name=$(printf '%s\n' "$info" | sed -n 's/^pkgname = //p')
        ;;
    esac
    if [ "$name" = "$package_name" ]; then
      rm -f "$artifact" "$artifact.sig"
    fi
  done
)
