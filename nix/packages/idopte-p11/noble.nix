{ stdenvNoCC, patchelf }:

stdenvNoCC.mkDerivation {
  pname = "idopte-p11-noble";
  version = "6.23.50.5-1";
  src = ../../../src/noble/idopte-p11_6.23.50.5-1_amd64;
  nativeBuildInputs = [ patchelf ];
  dontUnpack = true;
  dontBuild = true;
  # Preserve Debian/Ubuntu runtime paths; do not add Nix store references.
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -R "$src/." "$out/"
    chmod -R u+w "$out"
    rm -f "$out/.exclude"

    # RUNPATH applies to direct dependencies, so patch each XML consumer.
    for library in libdigidoc.so libpodofo.so libxmlsec1.so libxmlsec1-openssl.so; do
      elf="$out/usr/lib/SCMiddleware/$library"
      old_runpath=$(patchelf --print-rpath "$elf")
      patchelf --set-rpath "''${old_runpath:+$old_runpath:}\$ORIGIN/compat" "$elf"
    done
    runHook postInstall
  '';
}
