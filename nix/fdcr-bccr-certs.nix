{ lib, stdenvNoCC, openssl }:
stdenvNoCC.mkDerivation {
  pname = "fdcr-bccr-certs";
  version = "2026.08-1";
  src = ../src/ubuntu-noble/fdcr-bccr-certs_2026.08-1_all;
  nativeBuildInputs = [ openssl ];
  dontBuild = true;
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/fdcr-bccr-certs" "$out/etc/ssl/certs"
    cp -r usr/share/fdcr-bccr-certs/originals "$out/share/fdcr-bccr-certs/"
    sh usr/lib/fdcr-bccr-certs/build-pem \
      usr/share/fdcr-bccr-certs/originals "$out/share/fdcr-bccr-certs/pem"
    ln -s "$out/share/fdcr-bccr-certs/pem/roots.pem" "$out/etc/ssl/certs/fdcr-roots.pem"
    runHook postInstall
  '';
  meta = {
    description = "Certificados de la jerarquía nacional de Firma Digital de Costa Rica";
    homepage = "https://www.soportefirmadigital.com/";
    platforms = lib.platforms.all;
  };
}
