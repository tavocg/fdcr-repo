{ pkgs }:
  let
    toolchain = import ./toolchain.nix { inherit pkgs; };
  in pkgs.writeShellApplication
{
  name = "build-public";
  runtimeInputs = toolchain;
  text = ''
    set -euo pipefail
    export MAKEPKG_CONF="${pkgs.pacman}/etc/makepkg.conf"
    make all
  '';
}
