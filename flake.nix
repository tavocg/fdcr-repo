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
          # This flake explicitly provides the proprietary Idopte middleware.
          config.allowUnfreePredicate = pkg: nixpkgs.lib.getName pkg == "fdcr-middleware-idopte";
        }
      );
    in
    {
      # Packages currently target x86_64 Linux.
      packages.x86_64-linux = import ./nix/packages.nix { pkgs = pkgsFor.x86_64-linux; };

      nixosModules.default =
        { config, lib, ... }:
        let
          cfg = config.services.fdcr;
        in
        {
          options.services.fdcr = {
            enable = lib.mkEnableOption "Firma Digital de Costa Rica";

            package = lib.mkOption {
              type = lib.types.package;
              default = self.packages.x86_64-linux.fdcr-middleware-idopte;
              description = "Paquete del middleware Idopte.";
            };
          };

          config = lib.mkIf cfg.enable {
            services.pcscd.enable = true;

            environment.etc."idoss.conf".source = "${cfg.package}/etc/idoss.conf";

            environment.etc."idoss.lic".source = "${cfg.package}/etc/idoss.lic";

            systemd.tmpfiles.rules = [
              "d /usr/lib/SCMiddleware 0755 root root -"
              "L+ /usr/lib/SCMiddleware/libt_ias.so - - - - ${cfg.package}/lib/SCMiddleware/libt_ias.so"
              "L+ /usr/lib/SCMiddleware/idocachesrv - - - - ${cfg.package}/lib/SCMiddleware/idocachesrv"
            ];
          };
        };

      devShells = forAllSystems (system: {
        default = import ./nix/shell.nix { pkgs = pkgsFor.${system}; };
      });

      formatter = forAllSystems (system: pkgsFor.${system}.nixfmt-tree);
    };
}
