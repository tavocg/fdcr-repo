{ pkgs }:

let
  packages = {
    "fdcr-middleware-idopte-6.23.50.5-1" = pkgs.callPackage ./fdcr-middleware-idopte.nix {
      version = "6.23.50.5-1";
    };

    fdcr-middleware-idopte = packages."fdcr-middleware-idopte-6.23.50.5-1";
    default = packages.fdcr-middleware-idopte;
  };
in
packages
