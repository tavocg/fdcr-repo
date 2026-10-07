{ self }: { config, lib, pkgs, ... }:
  let
    cfg = config.services.fdcr;
    system = pkgs.stdenv.hostPlatform.system;

    middleware =
      if system == "x86_64-linux" then
        self.packages.x86_64-linux.fdcr-middleware-idopte
      else
        throw "FDCR: el middleware Idopte actualmente solo está disponible para x86_64-linux";
  in
{
  options.services.fdcr = {
    enable = lib.mkEnableOption "Firma Digital de Costa Rica";

    package = lib.mkOption {
      type = lib.types.package;
      default = middleware;
      description = "Paquete del middleware Idopte.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.pcscd.enable = true;

    environment.etc = {
      "idoss.conf".source = "${cfg.package}/etc/idoss.conf";
      "idoss.lic".source = "${cfg.package}/etc/idoss.lic";
    };

    systemd.tmpfiles.rules = [
      "d /usr/lib/SCMiddleware 0755 root root -"
      "L+ /usr/lib/SCMiddleware/libt_ias.so - - - - ${cfg.package}/lib/SCMiddleware/libt_ias.so"
      "L+ /usr/lib/SCMiddleware/idocachesrv - - - - ${cfg.package}/lib/SCMiddleware/idocachesrv"
    ];
  };
}
