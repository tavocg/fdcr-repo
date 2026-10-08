{ lib, stdenvNoCC }:
stdenvNoCC.mkDerivation {
  pname = "bccr-certs-jammy";
  version = "2026.08-1";
  dontUnpack = true;
  # Debian maintainer scripts must use the target system shell, not Nix store paths.
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -R ${../../../src/noble/bccr-certs_2026.08-1_all}/. "$out/"
    runHook postInstall
  '';

  meta = {
    description = "Certificados BCCR para Ubuntu 22.04 LTS";
    platforms = lib.platforms.linux;
  };
}
