{ pkgs }:

with pkgs; [
  # Build orchestration
  gnumake

  # POSIX/common tools
  bash
  coreutils
  findutils
  gnused
  gnugrep
  gawk
  diffutils
  file
  which

  # Archive/compression
  gnutar
  gzip
  bzip2
  xz
  zstd
  unzip
  unar
  p7zip
  cpio
  ncompress
  libarchive

  # Debian / Ubuntu
  dpkg
  apt

  # RPM / DNF
  rpm
  createrepo_c

  # Arch Linux
  pacman
  fakeroot

  # Signing
  gnupg

  # Binary manipulation
  binutils

  # Source/build helpers
  git
  git-lfs
  patch
  pkg-config

  # Useful if a PKGBUILD eventually compiles something
  gcc
]
