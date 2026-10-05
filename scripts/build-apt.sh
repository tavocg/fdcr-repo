#!/bin/sh
set -eu

ORIGIN="Soporte Firma Digital"
LABEL="Repositorio APT de Soporte Firma Digital"
SUITE="stable"
CODENAME="stable"
COMPONENT="main"
DESCRIPTION="Repositorio oficial de paquetes de Soporte Firma Digital"

# Optional.
# Example:
#   GPG_KEY_ID="ABCDEF1234567890" ./build-apt.sh
GPG_KEY_ID="${GPG_KEY_ID:-}"

SOURCE="./src/apt"
PUBLIC="./public/apt"

POOL="$PUBLIC/pool/$COMPONENT"
DIST="$PUBLIC/dists/$CODENAME"
DIST_MAIN="$DIST/$COMPONENT"

mkdir -p "$POOL"
mkdir -p "$DIST_MAIN"

# --------------------------------------------------
# 1. Build .deb packages
# --------------------------------------------------

for pkg in "$SOURCE"/*; do
  if [ ! -d "$pkg" ]; then
    continue
  fi

  # Expected directory name:
  #
  # package_version_arch
  #
  # Example:
  # firmador_1.0.0_amd64
  #
  arch="${pkg##*_}"

  arch_dir="$DIST_MAIN/binary-$arch"

  mkdir -p "$arch_dir"

  dpkg-deb \
    --root-owner-group \
    --build "$pkg" \
    "$POOL"
done

# --------------------------------------------------
# 2. Generate Packages / Packages.gz
# --------------------------------------------------

architectures=""

for arch_dir in "$DIST_MAIN"/binary-*; do
  if [ ! -d "$arch_dir" ]; then
    continue
  fi

  arch="${arch_dir##*-}"

  (
    cd "$PUBLIC"

    dpkg-scanpackages \
      --arch "$arch" \
      "pool/$COMPONENT" \
      >"dists/$CODENAME/$COMPONENT/binary-$arch/Packages"

    gzip \
      -9 \
      -c "dists/$CODENAME/$COMPONENT/binary-$arch/Packages" \
      >"dists/$CODENAME/$COMPONENT/binary-$arch/Packages.gz"
  )

  if [ -z "$architectures" ]; then
    architectures="$arch"
  else
    architectures="$architectures $arch"
  fi
done

if [ -z "$architectures" ]; then
  echo "Error: no package architectures were found." >&2
  exit 1
fi

# --------------------------------------------------
# 3. Generate Release
# --------------------------------------------------

apt-ftparchive \
  -o "APT::FTPArchive::Release::Origin=$ORIGIN" \
  -o "APT::FTPArchive::Release::Label=$LABEL" \
  -o "APT::FTPArchive::Release::Suite=$SUITE" \
  -o "APT::FTPArchive::Release::Codename=$CODENAME" \
  -o "APT::FTPArchive::Release::Architectures=$architectures" \
  -o "APT::FTPArchive::Release::Components=$COMPONENT" \
  -o "APT::FTPArchive::Release::Description=$DESCRIPTION" \
  release "$DIST" \
  >"$DIST/Release"

# --------------------------------------------------
# 4. Sign repository
# --------------------------------------------------

rm -f \
  "$DIST/InRelease" \
  "$DIST/Release.gpg"

if [ -n "$GPG_KEY_ID" ]; then
  echo "Signing repository with GPG key: $GPG_KEY_ID"

  # Clearsigned Release file.
  # Modern APT clients normally prefer InRelease.
  gpg \
    --batch \
    --yes \
    --local-user "$GPG_KEY_ID" \
    --clearsign \
    --output "$DIST/InRelease" \
    "$DIST/Release"

  # Detached signature for compatibility.
  gpg \
    --batch \
    --yes \
    --local-user "$GPG_KEY_ID" \
    --armor \
    --detach-sign \
    --output "$DIST/Release.gpg" \
    "$DIST/Release"
else
  echo "Warning: GPG_KEY_ID is not set."
  echo "Repository generated without a signature."
fi
