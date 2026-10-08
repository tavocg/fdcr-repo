{ stdenvNoCC, firmador }:

assert firmador.version == "2.0.0";

stdenvNoCC.mkDerivation {
  pname = "firmador-noble";
  version = "2.0.0-1";
  dontUnpack = true;
  # This tree targets Ubuntu, so preserve its shell and Java runtime paths.
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/usr/share/applications" "$out/usr/bin"
    cp -r ${firmador.jar}/share/firmador "$out/usr/share/"
    cp -r ${firmador.jar}/share/icons "$out/usr/share/"
    chmod -R u+w "$out/usr/share"
    install -Dm644 ${../../../src/noble/firmador_2.0.0-1_all/DEBIAN/control} "$out/DEBIAN/control"
    install -Dm644 ${firmador.jar.src}/flatpak/cr.libre.firmador.png \
      "$out/usr/share/icons/hicolor/128x128/apps/firmador.png"
    substitute ${firmador.jar.src}/flatpak/cr.libre.firmador.desktop \
      "$out/usr/share/applications/firmador.desktop" \
      --replace-fail 'Exec=cr.libre.firmador.sh %f' 'Exec=firmador %U' \
      --replace-fail 'Icon=cr.libre.firmador' 'Icon=firmador' \
      --replace-fail 'MimeType=application/pdf;' 'MimeType=x-scheme-handler/firmador;application/pdf;'
    install -Dm644 ${firmador.jar.src}/AUTHORS.md "$out/usr/share/doc/firmador/AUTHORS.md"
    install -Dm644 ${firmador.jar.src}/COPYING "$out/usr/share/doc/firmador/copyright"
    substitute ${./launcher.sh} "$out/usr/bin/firmador" \
      --subst-var-by shell /bin/bash \
      --subst-var-by java '"/usr/lib/jvm/java-21-openjdk-$(dpkg --print-architecture)/bin/java"' \
      --subst-var-by jar /usr/share/firmador/firmador.jar
    chmod 755 "$out/usr/bin/firmador"
    runHook postInstall
  '';
}
