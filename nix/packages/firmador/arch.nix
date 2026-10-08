{ stdenvNoCC, firmador }:

assert firmador.version == "2.0.0";

stdenvNoCC.mkDerivation {
  pname = "firmador-arch";
  version = "2.0.0-1";
  dontUnpack = true;
  # Preserve Arch system paths in the generated package payload.
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    rootfs="$out/rootfs"
    mkdir -p "$rootfs/usr/bin" "$rootfs/usr/share/applications" \
      "$rootfs/usr/share/doc/firmador" "$rootfs/usr/share/icons/hicolor/128x128/apps"
    cp -r ${firmador.jar}/share/firmador "$rootfs/usr/share/"
    cp -r ${firmador.jar}/share/icons "$rootfs/usr/share/"
    chmod -R u+w "$rootfs/usr/share"
    install -Dm644 ${firmador.jar.src}/flatpak/cr.libre.firmador.png \
      "$rootfs/usr/share/icons/hicolor/128x128/apps/firmador.png"
    substitute ${firmador.jar.src}/flatpak/cr.libre.firmador.desktop \
      "$rootfs/usr/share/applications/firmador.desktop" \
      --replace-fail 'Exec=cr.libre.firmador.sh %f' 'Exec=firmador %U' \
      --replace-fail 'Icon=cr.libre.firmador' 'Icon=firmador' \
      --replace-fail 'MimeType=application/pdf;' 'MimeType=x-scheme-handler/firmador;application/pdf;'
    install -Dm644 ${firmador.jar.src}/AUTHORS.md "$rootfs/usr/share/doc/firmador/AUTHORS.md"
    install -Dm644 ${firmador.jar.src}/COPYING "$rootfs/usr/share/doc/firmador/copyright"
    substitute ${./launcher.sh} "$rootfs/usr/bin/firmador" \
      --subst-var-by shell /bin/bash \
      --subst-var-by java java \
      --subst-var-by jar /usr/share/firmador/firmador.jar
    chmod 755 "$rootfs/usr/bin/firmador"
    runHook postInstall
  '';
}
