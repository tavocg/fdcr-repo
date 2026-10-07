{
  description = "Paquetes de Firma Digital para Costa Rica";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs, ... }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ];
      pkgsFor = forAllSystems (
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [
            "fdcr-middleware-idopte"
            "fdcr-scmanager"
            "fdcr-scmanager-unwrapped"
          ];
        }
      );
    in
    {
      packages.x86_64-linux =
        (import ./nix/packages.nix {
          pkgs = pkgsFor.x86_64-linux;
        })
        // {
          build-public = import ./nix/build-public.nix {
            pkgs = pkgsFor.x86_64-linux;
          };
        };

      legacyPackages.x86_64-linux = import ./nix/packages.nix { pkgs = pkgsFor.x86_64-linux; };

      nixosModules = {
        fdcr = import ./nix/modules/fdcr.nix {
          inherit self;
        };
        default = self.nixosModules.fdcr;
      };

      devShells = forAllSystems (system: {
        default = import ./nix/shell.nix { pkgs = pkgsFor.${system}; };
      });

      formatter = forAllSystems (system: pkgsFor.${system}.nixfmt-tree);
    };
}
