{ lib, buildFHSEnv }:
let
  src = ../src/noble/fdcr-bccr-gaudi_29.0-1_amd64;
in
buildFHSEnv {
  pname = "fdcr-bccr-gaudi";
  version = "29.0-1";
  executableName = "agente-gaudi";
  # Keep the vendor Java/JavaFX runtime and the fixed /opt paths used by its
  # updater. User data lives in the real home, outside the immutable Nix store.
  targetPkgs = pkgs: [
    pkgs.bash
    pkgs.coreutils
    pkgs.xdg-utils
    pkgs.cacert
    pkgs.stdenv.cc.cc.lib
    pkgs.zlib
    pkgs.glib
    pkgs.gtk2
    pkgs.gtk3
    pkgs.atk
    pkgs.cairo
    pkgs.pango
    pkgs.gdk-pixbuf
    pkgs.fontconfig
    pkgs.freetype
    pkgs.alsa-lib
    pkgs.libGL
    pkgs.libX11
    pkgs.libXext
    pkgs.libXi
    pkgs.libXrender
    pkgs.libXtst
    pkgs.libXxf86vm
    pkgs.pcsclite
    pkgs.dbus
    pkgs.systemd
  ];
  multiPkgs = null;
  extraBuildCommands = ''
    mkdir -p "$out/opt/Agente-GAUDI"
  '';
  extraBwrapArgs = [ "--ro-bind ${src}/opt/Agente-GAUDI /opt/Agente-GAUDI" ];
  runScript = "/opt/Agente-GAUDI/bin/Agente-GAUDI";
  extraInstallCommands = ''
    mkdir -p "$out/share/applications" "$out/share/icons/hicolor/128x128/apps" "$out/etc/xdg/autostart"
    cp ${src}/opt/Agente-GAUDI/lib/Agente-GAUDI.png "$out/share/icons/hicolor/128x128/apps/agente-gaudi.png"
    cp ${src}/usr/share/applications/Agente-GAUDI.desktop "$out/share/applications/"
    substituteInPlace "$out/share/applications/Agente-GAUDI.desktop" \
      --replace-fail 'Version=29.0' 'Version=1.0' \
      --replace-fail /opt/Agente-GAUDI/bin/Agente-GAUDI "$out/bin/agente-gaudi" \
      --replace-fail /opt/Agente-GAUDI/lib/Agente-GAUDI.png agente-gaudi
    cp "$out/share/applications/Agente-GAUDI.desktop" "$out/etc/xdg/autostart/"
  '';
  meta = {
    description = "Agente GAUDI del Banco Central de Costa Rica";
    homepage = "https://www.soportefirmadigital.com/";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "agente-gaudi";
  };
}
