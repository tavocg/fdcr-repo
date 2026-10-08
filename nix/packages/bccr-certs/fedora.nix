{ lib, stdenvNoCC, openssl }:
stdenvNoCC.mkDerivation {
  pname = "bccr-certs-fedora";
  version = "2026.08-1";
  src = ../../../src/noble/bccr-certs_2026.08-1_all;
  nativeBuildInputs = [ openssl ];
  dontBuild = true;
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/rootfs/usr/share/bccr-certs" \
      "$out/rootfs/usr/libexec/bccr-certs"
    cp -R usr/share/bccr-certs/originals "$out/rootfs/usr/share/bccr-certs/"
    install -m 755 ${./install} "$out/rootfs/usr/libexec/bccr-certs/install"
    install -m 755 ${./remove} "$out/rootfs/usr/libexec/bccr-certs/remove"
    runHook postInstall
  '';
  meta = {
    description = "Certificados BCCR para Fedora";
    platforms = lib.platforms.linux;
  };
}
