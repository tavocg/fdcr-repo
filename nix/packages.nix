{ pkgs }:

let
  packages = {
    firmador_1_9 = pkgs.callPackage ./firmador.nix {
      version = "1.9.8";
      rev = "09953947a51d87c2a146189ec76b6c27ab6518a1";
      hash = "sha256-xdiVPjihRADPK4nG+WQHWsDzVYLCeN6ouQ6SDtjf1qQ=";
      mvnHash = "sha256-opTjZA50tInbAmfGT1rJI3cC0+dUdYrIh8ZWReVeKWA=";
      patches = [ ./patches/firmador-1.9.8-libasep11.patch ];
    };

    firmador_2_0 = pkgs.callPackage ./firmador.nix {
      version = "2.0.0";
      rev = "a34e5b87b62093b22de95a543cf7edd303ec2676";
      hash = "sha256-ykDHGr1jdAkClgCVPVEIQWyo9idxjFfOem9TD1S6t9I=";
      mvnHash = "sha256-X6hxe5v+w+0RtKYeAOjRy2HFetH8LeCBNauZQq+I928=";
    };

    firmador = packages.firmador_2_0;

    "fdcr-middleware-idopte-6.23.50.5-1" = pkgs.callPackage ./fdcr-middleware-idopte.nix {
      version = "6.23.50.5-1";
    };

    fdcr-middleware-idopte = packages."fdcr-middleware-idopte-6.23.50.5-1";
    default = packages.fdcr-middleware-idopte;
  };
in
packages
