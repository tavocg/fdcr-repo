{
  lib,
  stdenvNoCC,
  stdenv,
  autoPatchelfHook,
  bzip2,
  brotli,
  expat,
  fontconfig,
  freetype,
  libpng,
  libxml2_13,
  pcsclite,
  zlib,
  version,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "idopte-p11";
  inherit version;

  src = ../src/noble + "/${finalAttrs.pname}_${finalAttrs.version}_amd64";
  dontBuild = true;

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [
    stdenv.cc.cc.lib
    bzip2
    brotli
    expat
    fontconfig
    freetype
    libpng
    libxml2_13
    pcsclite
    zlib
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p "$out" "$out/etc"
    cp -a usr/. "$out/"
    cp -a etc/. "$out/etc/"
    runHook postInstall
  '';

  meta = {
    description = "Middleware PKCS#11 Idopte para firma digital de Costa Rica";
    homepage = "https://www.soportefirmadigital.com/";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
