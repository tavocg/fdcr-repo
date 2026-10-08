#!/bin/sh

set -eu

if [ "$(id -u)" -ne 0 ]; then
  echo "error: must be run as root" >&2
  exit 1
fi

REPO_ROOT="https://tavocg.github.io/fdcr-repo"
REPO_KEY="fdcr.asc"

_install_apt() {
  codename="$1"
  component="${2:-main}"

  curl -fsSLo "/usr/share/keyrings/$REPO_KEY" "$REPO_ROOT/$REPO_KEY"
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/$REPO_KEY] $REPO_ROOT/$codename $codename $component" |
    tee /etc/apt/sources.list.d/fdcr.list
  apt-get update
}

SUPPORTED="${SUPPORTED:+$SUPPORTED }ubuntu2404"
_install_ubuntu2404() {
  _install_apt "noble"
}

SUPPORTED="${SUPPORTED:+$SUPPORTED }debian13"
_install_debian13() {
  _install_ubuntu2404
}

SUPPORTED="${SUPPORTED:+$SUPPORTED }ubuntu2204"
_install_ubuntu2204() {
  _install_apt "jammy"
}

SUPPORTED="${SUPPORTED:+$SUPPORTED }fedora44"
_install_fedora44() {
  tmp="$(mktemp)"

  curl -fsSLo "$tmp" "$REPO_ROOT/$REPO_KEY"
  install -Dm644 "$tmp" "/etc/pki/rpm-gpg/$REPO_KEY"
  rm -f "$tmp"
  rpm --import "/etc/pki/rpm-gpg/$REPO_KEY"

  tee "/etc/yum.repos.d/fdcr.repo" >/dev/null <<'INI'
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
  tmp="$(mktemp)"
  curl -fsSLo "$tmp" "$REPO_ROOT/$REPO_KEY"
  pacman-key --add "$tmp"
  pacman-key --lsign-key "$(gpg --show-keys --with-colons "$tmp" | sed -n '/^fpr:/ { s/:$//; s/.*://; p; q; }')"
  rm -f "$tmp"

  mkdir -p "/etc/pacman.d/repos.d"
  tee "/etc/pacman.d/repos.d/fdcr.conf" >/dev/null <<'INI'
[fdcr]
SigLevel = Required
Server = https://tavocg.github.io/fdcr-repo/arch/
INI

  if ! grep -Eq '^ *Include *= */etc/pacman\.d/repos\.d/\*\.conf *(#.*)?$' /etc/pacman.conf; then
    printf '\nInclude = /etc/pacman.d/repos.d/*.conf\n' >>/etc/pacman.conf
  fi

  pacman -Sy
}

_get_release() {
  for r in "/etc/os-release" "/usr/lib/os-release"; do
    if [ -n "$r" ] && [ -f "$r" ] && [ -r "$r" ]; then
      #shellcheck disable=SC1090
      . "$r"
      break
    fi
  done

  : "${RELEASE:="${ID}${VERSION_ID:-}"}"
  RELEASE="$(printf '%s' "$RELEASE" | tr -d '.')"

  case " $SUPPORTED " in
  *" $RELEASE "*) echo "$RELEASE" ;;
  *)
    printf "error: unsupported release '%s', install manually\n\nsupported:\n  %s\n" \
      "$RELEASE" "$SUPPORTED" >&2
    return 1
    ;;
  esac
}

release="$(_get_release)"

_install_"$release"
