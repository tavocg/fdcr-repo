{ pkgs }:
  let
    toolchain = import ./toolchain.nix { inherit pkgs; };
  in pkgs.mkShell
{
  packages = toolchain;
  shellHook = ''
    export MAKEPKG_CONF="${pkgs.pacman}/etc/makepkg.conf"
    case "$PS1" in
    "(fdcr-repo) "*) ;;
    *) export PS1="(fdcr-repo) $PS1" ;;
    esac
  '';
}
