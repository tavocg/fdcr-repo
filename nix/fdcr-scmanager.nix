{
  lib,
  stdenvNoCC,
  stdenv,
  autoPatchelfHook,
  buildFHSEnv,
  writeShellScript,
  glib,
  gtk3,
  libappindicator-gtk3,
  libnotify,
  pcsclite,
  webkitgtk_4_1,
  procps,
  zenity,
  middleware,
  version,
  nautilusSupport ? false,
}:

let
  src = ../src/ubuntu-noble + "/fdcr-scmanager_${version}_amd64";
  meta = {
    description = "Administrador gráfico SCManager de Idopte";
    homepage = "https://www.soportefirmadigital.com/";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "SCManager";
  };
  unwrapped = stdenvNoCC.mkDerivation {
    pname = "fdcr-scmanager-unwrapped";
    inherit version src;
    dontBuild = true;
    nativeBuildInputs = [ autoPatchelfHook ];
    buildInputs = [
      stdenv.cc.cc.lib
      middleware
      glib
      gtk3
      libappindicator-gtk3
      libnotify
      pcsclite
      webkitgtk_4_1
    ];
    preFixup = ''
      addAutoPatchelfSearchPath ${middleware}/lib/SCMiddleware
    '';
    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      cp -a usr/. "$out/"
      cp -a etc "$out/"
      runHook postInstall
    '';
    inherit meta;
  };
in
buildFHSEnv {
  pname = "fdcr-scmanager";
  inherit version meta;
  executableName = "SCManager";
  # Vendor binaries and Python helpers use fixed /usr/{lib,share}/SCMiddleware
  # paths. Provide them inside the FHS environment without changing the host.
  targetPkgs = pkgs: [
    unwrapped
    middleware
    pkgs.bash
    pkgs.coreutils
    pkgs.gnugrep
    pkgs.gnused
    # SCManager shells out to openssl/awk and reads GNOME proxy settings.
    # Library closures alone do not provide these executables or schemas.
    pkgs.gawk
    (lib.getBin pkgs.openssl)
    (lib.getBin pkgs.glib)
    pkgs.gsettings-desktop-schemas
    pkgs.procps
    pkgs.lsof
    pkgs.zenity
    pkgs.xdg-utils
    pkgs.xdg-user-dirs
    pkgs.cacert
    (pkgs.python3.withPackages (ps: [ ps.requests ]))
  ];
  multiPkgs = null;
  runScript = writeShellScript "scmanager-launch" ''
    if [ "''${1:-}" = "--nautilus-request" ]; then
      shift
      exec /usr/bin/python3 -c 'import json, sys; sys.path.insert(0, "/usr/share/SCMiddleware"); import crypto_common; crypto_common.send_request(json.loads(sys.argv[2]), sys.argv[1])' "$@"
    fi
    if [ "''${1:-}" = "--open-pkcs7" ]; then
      shift
      exec /usr/bin/python3 /usr/share/SCMiddleware/open_pkcs7.py "$@"
    fi
    exec /usr/lib/SCMiddleware/SCManager "$@"
  '';
  extraInstallCommands = ''
    mkdir -p "$out/share/applications" "$out/share/mime/packages" "$out/etc/xdg/autostart"
    cp ${src}/usr/share/applications/*.desktop "$out/share/applications/"
    cp ${src}/usr/share/mime/packages/*.xml "$out/share/mime/packages/"
    cp ${src}/etc/xdg/autostart/*.desktop "$out/etc/xdg/autostart/"
    substituteInPlace "$out/share/applications/SCManager.desktop" \
      "$out/etc/xdg/autostart/SCManager.desktop" \
      --replace-fail /usr/lib/SCMiddleware/SCManager "$out/bin/SCManager" \
      --replace-fail /usr/share/SCMiddleware/application.png "${middleware}/share/SCMiddleware/application.png"
    substituteInPlace "$out/share/applications/pkcs7.desktop" \
      --replace-fail '/usr/bin/python3 /usr/share/SCMiddleware/open_pkcs7.py' "$out/bin/SCManager --open-pkcs7"
  '' + lib.optionalString nautilusSupport ''
    mkdir -p "$out/share/nautilus-python/extensions" "$out/share/fdcr-scmanager"
    cp ${src}/usr/share/nautilus-python/extensions/CryptoshellExtension.py \
      "$out/share/nautilus-python/extensions/"
    substituteInPlace "$out/share/nautilus-python/extensions/CryptoshellExtension.py" \
      --replace-fail /usr/share/SCMiddleware "$out/share/fdcr-scmanager" \
      --replace-fail /usr/share/in_p11 "$out/share/fdcr-scmanager" \
      --replace-fail 'import crypto_common' 'import fdcr_crypto_common as crypto_common' \
      --replace-fail '"pidof"' '"${procps}/bin/pidof"'
    substitute ${./scmanager-nautilus.py} "$out/share/fdcr-scmanager/fdcr_crypto_common.py" \
      --subst-var-by scmanager "$out/bin/SCManager" \
      --subst-var-by middleware "${middleware}" \
      --subst-var-by zenity "${zenity}/bin/zenity"
  '';
  passthru = { inherit middleware unwrapped nautilusSupport; };
}
