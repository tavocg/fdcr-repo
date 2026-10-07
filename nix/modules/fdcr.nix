{ self }: { config, lib, pkgs, ... }:
  let
    cfg = config.services.fdcr;
    system = pkgs.stdenv.hostPlatform.system;

    middleware =
      if system == "x86_64-linux" then
        self.packages.x86_64-linux.fdcr-middleware-idopte
      else
        throw "FDCR: el middleware Idopte actualmente solo está disponible para x86_64-linux";

    # NixOS does not expose programs.nautilus.enable. GNOME installs Nautilus
    # unless explicitly excluded; other desktops can opt in below.
    gnomeHasNautilus =
      (config.services.desktopManager.gnome.enable or false)
      && (config.services.gnome.core-apps.enable or false)
      && !(lib.any (package: lib.getName package == "nautilus") config.environment.gnome.excludePackages);
    scmanager = cfg.scmanager.package.override {
      nautilusSupport = cfg.scmanager.nautilus.enable;
      middleware = cfg.package;
    };
  in
{
  options.services.fdcr = {
    enable = lib.mkEnableOption "Firma Digital de Costa Rica";

    package = lib.mkOption {
      type = lib.types.package;
      default = middleware;
      description = "Paquete del middleware Idopte.";
    };

    scmanager = {
      enable = lib.mkEnableOption "SCManager y su integración de escritorio";
      package = lib.mkOption {
        type = lib.types.package;
        default = self.packages.${system}.fdcr-scmanager;
        description = "Paquete SCManager con soporte para override de nautilusSupport.";
      };
      nautilus.enable = lib.mkOption {
        type = lib.types.bool;
        default = gnomeHasNautilus;
        description = ''
          Habilita la extensión de SCManager para Nautilus. Se activa por defecto
          con GNOME si Nautilus no está excluido. En otros escritorios, habilitar
          únicamente cuando Nautilus esté instalado.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.pcscd.enable = true;

    environment.systemPackages = lib.mkIf cfg.scmanager.enable (
      [ scmanager ] ++ lib.optional cfg.scmanager.nautilus.enable pkgs.nautilus-python
    );
    environment.pathsToLink = lib.mkIf (cfg.scmanager.enable && cfg.scmanager.nautilus.enable) [
      "/share/nautilus-python/extensions"
    ];
    environment.sessionVariables = lib.mkIf (cfg.scmanager.enable && cfg.scmanager.nautilus.enable) {
      NAUTILUS_4_EXTENSION_DIR = "${config.system.path}/lib/nautilus/extensions-4";
    };

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
