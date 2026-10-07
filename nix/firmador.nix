{
  lib,
  stdenvNoCC,
  fetchFromCodeberg,
  maven,
  jdk21,
  jre ? jdk21,
  makeWrapper,
  makeDesktopItem,
  copyDesktopItems,
  version,
  rev,
  hash,
  mvnHash,
  patches ? [ ],
  pkcs11Module ? null,
}:

let
  jar = maven.buildMavenPackage {
    pname = "firmador-jar";
    inherit version patches mvnHash;

    src = fetchFromCodeberg {
      owner = "firmador";
      repo = "firmador";
      inherit rev hash;
    };

    mvnJdk = jdk21;
    doCheck = false;

    installPhase = ''
      runHook preInstall
      install -Dm644 target/firmador.jar "$out/share/firmador/firmador.jar"
      install -Dm644 src/main/resources/firmador.png "$out/share/icons/hicolor/1024x1024/apps/firmador.png"
      runHook postInstall
    '';
  };
in
stdenvNoCC.mkDerivation {
  pname = "firmador";
  inherit (jar) version;
  dontUnpack = true;

  nativeBuildInputs = [
    makeWrapper
    copyDesktopItems
  ];

  desktopItems = [
    (makeDesktopItem {
      name = "firmador";
      desktopName = "Firmador Libre";
      comment = "Firma digital de documentos";
      exec = "firmador %U";
      icon = "firmador";
      terminal = false;
      categories = [ "Office" ];
      mimeTypes = [ "x-scheme-handler/firmador" ];
      extraConfig.SingleMainWindow = "true";
    })
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin" "$out/share"
    ln -s ${jar}/share/firmador "$out/share/firmador"
    ln -s ${jar}/share/icons "$out/share/icons"
    substitute ${./firmador.sh} "$out/bin/firmador" \
      --subst-var-by shell ${stdenvNoCC.shell} \
      --subst-var-by java ${lib.getExe' jre "java"} \
      --subst-var-by jar ${jar}/share/firmador/firmador.jar
    chmod +x "$out/bin/firmador"
    ${lib.optionalString (pkcs11Module != null) ''
      wrapProgram "$out/bin/firmador" \
        --set-default LIBASEP11 ${lib.escapeShellArg (toString pkcs11Module)}
    ''}
    runHook postInstall
  '';

  # Keep middleware selection separate from the expensive Java compilation.
  passthru = { inherit jar; };

  meta = {
    description = "Firmador libre de documentos para Costa Rica";
    homepage = "https://codeberg.org/firmador/firmador";
    license = lib.licenses.gpl3Plus;
    mainProgram = "firmador";
    platforms = lib.platforms.linux;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
}
