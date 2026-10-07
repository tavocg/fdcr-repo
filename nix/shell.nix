{ pkgs }:

pkgs.mkShell {
  packages = with pkgs; [
    python3
    coreutils
    findutils
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
    rpm
    dpkg
    createrepo_c
    apt
    gnupg
    binutils
    pacman
    fakeroot
    git-lfs
  ];

  shellHook = ''
    export MAKEPKG_CONF="${pkgs.pacman}/etc/makepkg.conf"
    case "$PS1" in
    "(fdcr-repo) "*) ;;
    *) export PS1="(fdcr-repo) $PS1" ;;
    esac
  '';
}
