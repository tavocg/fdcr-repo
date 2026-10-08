{ stdenvNoCC, fetchurl, dpkg }:

stdenvNoCC.mkDerivation {
  pname = "libxml2-idopte-compat-noble";
  version = "2.9.14+deb13u3-1";

  # Debian's ABI 2 build needs only glibc >= 2.38, xz and zlib, all available
  # in Noble and Resolute. In particular it does not require Noble's ICU ABI.
  src = fetchurl {
    url = "https://deb.debian.org/debian/pool/main/libx/libxml2/libxml2_2.12.7+dfsg+really2.9.14-2.1+deb13u3_amd64.deb";
    hash = "sha256-4Ma2PORgKgNqUm9g/l5sFYZxBogFjZj8EAG5sxR7fv0=";
  };
  nativeBuildInputs = [ dpkg ];
  unpackPhase = ''
    dpkg-deb -x "$src" upstream
  '';
  dontBuild = true;
  # These ELF files run on Debian/Ubuntu, not against the Nix store.
  dontFixup = true;
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/usr/lib/SCMiddleware/compat" "$out/usr/share/doc/libxml2-idopte-compat"
    cp -a upstream/usr/lib/x86_64-linux-gnu/libxml2.so.2* "$out/usr/lib/SCMiddleware/compat/"
    cp -a upstream/usr/share/doc/libxml2/. "$out/usr/share/doc/libxml2-idopte-compat/"
    install -Dm644 ${../../../src/noble/libxml2-idopte-compat_2.9.14+deb13u3-1_amd64/DEBIAN/control} "$out/DEBIAN/control"
    runHook postInstall
  '';
}
