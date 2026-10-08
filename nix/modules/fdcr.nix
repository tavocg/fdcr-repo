{ self }: { config, lib, pkgs, ... }:
  let
    cfg = config.services.fdcr;
    system = pkgs.stdenv.hostPlatform.system;

    middleware =
      if system == "x86_64-linux" then
        self.packages.x86_64-linux.idopte-p11
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

    middleware.enable = lib.mkEnableOption "el middleware Idopte";

    package = lib.mkOption {
      type = lib.types.package;
      default = middleware;
      description = "Paquete del middleware Idopte.";
    };

    certificates = {
      enable = lib.mkEnableOption "las CA raíz de Firma Digital en el almacén del sistema";
      package = lib.mkOption {
        type = lib.types.package;
        default = self.packages.${system}.bccr-certs;
        description = "Paquete de certificados y conjuntos PEM de Firma Digital.";
      };
    };

    gaudi = {
      enable = lib.mkEnableOption "el agente GAUDI y su inicio de sesión gráfico";
      package = lib.mkOption {
        type = lib.types.package;
        default = self.packages.${system}.bccr-gaudi;
        description = "Paquete del agente GAUDI.";
      };
    };

    scmanager = {
      enable = lib.mkEnableOption "SCManager y su integración de escritorio";
      package = lib.mkOption {
        type = lib.types.package;
        default = self.packages.${system}.idopte-scmanager;
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

    services.fdcr.middleware.enable = lib.mkDefault cfg.scmanager.enable;
    security.pki.certificateFiles = lib.mkIf cfg.certificates.enable [
      "${cfg.certificates.package}/etc/ssl/certs/bccr-roots.pem"
    ];

    environment.systemPackages =
      lib.optional cfg.gaudi.enable cfg.gaudi.package
      ++ lib.optional cfg.certificates.enable cfg.certificates.package
      ++ lib.optionals cfg.scmanager.enable (
        [ scmanager ] ++ lib.optional cfg.scmanager.nautilus.enable pkgs.nautilus-python
      );
    environment.pathsToLink = lib.mkIf (cfg.scmanager.enable && cfg.scmanager.nautilus.enable) [
      "/share/nautilus-python/extensions"
    ];
    environment.sessionVariables = lib.mkIf (cfg.scmanager.enable && cfg.scmanager.nautilus.enable) {
      NAUTILUS_4_EXTENSION_DIR = "${config.system.path}/lib/nautilus/extensions-4";
    };

    environment.etc = lib.mkIf cfg.middleware.enable {
      "idoss.conf".source = "${cfg.package}/etc/idoss.conf";
      "idoss.lic".source = "${cfg.package}/etc/idoss.lic";
    };

    systemd.tmpfiles.rules = lib.mkIf cfg.middleware.enable [
      "d /usr/lib/SCMiddleware 0755 root root -"
      "L+ /usr/lib/SCMiddleware/libt_ias.so - - - - ${cfg.package}/lib/SCMiddleware/libt_ias.so"
      "L+ /usr/lib/SCMiddleware/idocachesrv - - - - ${cfg.package}/lib/SCMiddleware/idocachesrv"
    ];
  };
}
