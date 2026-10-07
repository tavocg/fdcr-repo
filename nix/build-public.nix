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

    case "''${1:-}" in
      --sign)
        if [ -f .env ]; then
          set -a
          . ./.env
          set +a
        fi

        if [ -z "''${GPG_KEY_ID:-}" ]; then
          echo "Error: GPG_KEY_ID is not set" >&2
          exit 1
        fi

        make sign
        ;;

      "")
        make repos
        ;;

      *)
        echo "Usage: build-public [--sign]" >&2
        exit 2
        ;;
    esac
  '';
}
