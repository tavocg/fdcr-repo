{ lib, stdenvNoCC }:
stdenvNoCC.mkDerivation {
  pname = "bccr-certs-arch";
  version = "2026.08-1";
  src = ../../../src/noble/bccr-certs_2026.08-1_all;
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
    description = "Certificados BCCR para Arch Linux";
    platforms = lib.platforms.linux;
  };
}
