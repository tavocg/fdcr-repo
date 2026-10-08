{
  lib,
  stdenvNoCC,
  openssl,
}:
stdenvNoCC.mkDerivation {
  pname = "bccr-certs";
  version = "2026.08-1";
  src = ../src/noble/bccr-certs_2026.08-1_all;
  nativeBuildInputs = [ openssl ];
  dontBuild = true;
  installPhase = ''
    runHook preInstall
    source_dir=usr/share/bccr-certs/originals
    output="$out/share/bccr-certs/pem"
    export LC_ALL=C
    mkdir -p "$out/share/bccr-certs" "$out/etc/ssl/certs" \
      "$output/certificates" "$output/roots"
    cp -r "$source_dir" "$out/share/bccr-certs/"
    : > "$output/bundle.pem"
    : > "$output/ca-bundle.pem"
    : > "$output/roots.pem"
    found=false
    for certificate in "$source_dir"/*; do
      [ -f "$certificate" ] || continue
      found=true
      temporary="$output/certificate.tmp"
      if ! openssl x509 -inform PEM -in "$certificate" -out "$temporary" 2>/dev/null; then
        if ! openssl x509 -inform DER -in "$certificate" -out "$temporary"; then
          echo "error: cannot parse certificate $certificate" >&2
          exit 1
        fi
      fi
      fingerprint=$(openssl x509 -in "$temporary" -noout -fingerprint -sha256)
      fingerprint=$(printf '%s' "''${fingerprint#*=}" | tr -d ':')
      pem="$output/certificates/$fingerprint.pem"
      if [ -f "$pem" ]; then
        rm -f "$temporary"
        continue
      fi
      mv "$temporary" "$pem"
      cat "$pem" >> "$output/bundle.pem"
      constraints=$(openssl x509 -in "$pem" -noout -ext basicConstraints)
      case "$constraints" in
        *CA:TRUE*)
          cat "$pem" >> "$output/ca-bundle.pem"
          subject=$(openssl x509 -in "$pem" -noout -subject -nameopt RFC2253)
          issuer=$(openssl x509 -in "$pem" -noout -issuer -nameopt RFC2253)
          if [ "''${subject#subject=}" = "''${issuer#issuer=}" ]; then
            cp "$pem" "$output/roots/$fingerprint.crt"
            cat "$pem" >> "$output/roots.pem"
          fi
          ;;
      esac
    done
    [ "$found" = true ] && [ -s "$output/roots.pem" ]
    ln -s "$out/share/bccr-certs/pem/roots.pem" "$out/etc/ssl/certs/bccr-roots.pem"
    runHook postInstall
  '';
  meta = {
    description = "Certificados de la jerarquía nacional de Firma Digital de Costa Rica";
    homepage = "https://www.soportefirmadigital.com/";
    platforms = lib.platforms.all;
  };
}
