{
  description = "Paquetes de Firma Digital para Costa Rica";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ];
      pkgsFor = forAllSystems (
        system:
        import nixpkgs {
          inherit system;
          # This flake explicitly provides the proprietary Idopte middleware.
          config.allowUnfreePredicate = pkg: nixpkgs.lib.getName pkg == "fdcr-middleware-idopte";
        }
      );
    in
    {
      # The vendor only provides x86_64 binaries.
      packages.x86_64-linux = import ./nix/packages.nix { pkgs = pkgsFor.x86_64-linux; };

      devShells = forAllSystems (system: {
        default = import ./nix/shell.nix { pkgs = pkgsFor.${system}; };
      });

      formatter = forAllSystems (system: pkgsFor.${system}.nixfmt-tree);
    };
}
