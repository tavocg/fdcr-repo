#!/bin/sh

set -eu

if [ "$(id -u)" -neq 0 ]; then
  echo "error: must be run as root" >&2
  exit 1
fi

REPO_ROOT="https://tavocg.github.io/fdcr-repo"
REPO_KEY="fdcr.asc"

SUPPORTED="${SUPPORTED:+$SUPPORTED }ubuntu24.04"
_install_ubuntu2404() {
  codename="noble"
  component="main"

  curl -fsSLo "/usr/share/keyrings/$REPO_KEY" "$REPO_ROOT/$REPO_KEY"

  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/$REPO_KEY] $REPO_ROOT/$codename $codename $component" |
    tee /etc/apt/sources.list.d/fdcr.list

  apt-get update
}

SUPPORTED="${SUPPORTED:+$SUPPORTED }debian13"
_install_debian13() {
  _install_ubuntu2404
}

SUPPORTED="${SUPPORTED:+$SUPPORTED }ubuntu22.04"
_install_ubuntu2204() {
  codename="jammy"
  component="main"

  curl -fsSLo "/usr/share/keyrings/$REPO_KEY" "$REPO_ROOT/$REPO_KEY"

  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/$REPO_KEY] $REPO_ROOT/$codename $codename $component" |
    tee /etc/apt/sources.list.d/fdcr.list

  apt-get update
}

SUPPORTED="${SUPPORTED:+$SUPPORTED }fedora44"
_install_fedora44() {
  repo="/etc/yum.repos.d/fdcr.repo"
  tmp="/tmp/$REPO_KEY"

  curl -fsSLo "$tmp" "$REPO_ROOT/$REPO_KEY"
  sudo install -Dm644 "$tmp" "/etc/pki/rpm-gpg/$REPO_KEY"
  rm -f "$tmp"
  sudo rpm --import "/etc/pki/rpm-gpg/$REPO_KEY"

  sudo tee "$repo" >/dev/null <<'INI'
[fdcr]
name=FDCR Repository
baseurl=https://tavocg.github.io/fdcr-repo/fedora/
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/fdcr.asc
INI
}

SUPPORTED="${SUPPORTED:+$SUPPORTED }arch"
_install_arch() {
  tmp="/tmp/$REPO_KEY"

  curl -fsSLo "$tmp" "$REPO_ROOT/$REPO_KEY"
  sudo pacman-key --add "$tmp"
  sudo pacman-key --lsign-key "$(gpg --show-keys --with-colons "$tmp" | sed '/fpr/!d;s/:$//;s/.*://')"
  rm -f "$tmp"
}

_get_release() {
  for r in "/etc/os-release" "/usr/lib/os-release"; do
    if [ -n "$r" ] && [ -f "$r" ] && [ -r "$r" ]; then
      #shellcheck disable=SC1090
      . "$r"
    fi
  done

  : "${RELEASE:="${ID}${VERSION_ID:-}"}"

  case " $RELEASE " in
  " $SUPPORTED ") echo "$RELEASE" ;;
  *)
    printf "error: unsupported release '%s', install manually\n\nsupported:\n  %s\n" \
      "$RELEASE" "$SUPPORTED" >&2
    return 1
    ;;
  esac
}

release="$(_get_release)"

_install_"$release"
