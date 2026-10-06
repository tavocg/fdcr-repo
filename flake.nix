{
  description = "Paquetes de Firma Digital para Costa Rica";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      # El middleware distribuido aquí contiene binarios x86_64.
      packageSystems = [ "x86_64-linux" ];
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];

      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      forPackageSystems = nixpkgs.lib.genAttrs packageSystems;
    in
    {
      packages = forPackageSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };
          sourceRoot = ./src/ubuntu-noble;
          packagePrefix = "fdcr-middleware-idopte_";
          packageSuffix = "_amd64";
          packageDirs = builtins.filter
            (name:
              (builtins.readDir sourceRoot).${name} == "directory"
              && pkgs.lib.hasPrefix packagePrefix name
              && pkgs.lib.hasSuffix packageSuffix name)
            (builtins.attrNames (builtins.readDir sourceRoot));
          versionOf = name:
            let
              withoutPrefix = pkgs.lib.removePrefix packagePrefix name;
            in
            pkgs.lib.removeSuffix packageSuffix withoutPrefix;
          sortedPackageDirs = pkgs.lib.sort
            (a: b: pkgs.lib.versionOlder (versionOf a) (versionOf b))
            packageDirs;
          mkPackage = packageDir:
            let
              version = versionOf packageDir;
            in
            pkgs.stdenvNoCC.mkDerivation {
              pname = "fdcr-middleware-idopte";
              inherit version;
              src = sourceRoot + "/${packageDir}";
              dontBuild = true;
              nativeBuildInputs = [ pkgs.autoPatchelfHook ];
              buildInputs = with pkgs; [
                stdenv.cc.cc.lib
                bzip2
                brotli
                expat
                fontconfig
                freetype
                glib
                gtk3
                libappindicator-gtk3
                libnotify
                libpng
                libxml2
                pcsclite
                webkitgtk_4_1
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
                license = pkgs.lib.licenses.unfree;
                platforms = [ "x86_64-linux" ];
                sourceProvenance = [ pkgs.lib.sourceTypes.binaryNativeCode ];
              };
            };
          latestPackageDir = builtins.elemAt sortedPackageDirs (builtins.length sortedPackageDirs - 1);
          versionedPackages = builtins.listToAttrs (map
            (packageDir: {
              name = "fdcr-middleware-idopte-${versionOf packageDir}";
              value = mkPackage packageDir;
            })
            sortedPackageDirs);
        in
        versionedPackages // {
          default = mkPackage latestPackageDir;
          fdcr-middleware-idopte = mkPackage latestPackageDir;
        }
      );

      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              python3
              coreutils
              findutils
              gnutar
              gzip
              bzip2
              xz
              zstd
              unzip
              unar
              p7zip
              cpio
              ncompress
              rpm
              dpkg
              createrepo_c
              apt
              gnupg
              binutils
              pacman
              fakeroot
              git-lfs
            ];

            shellHook = ''
              export MAKEPKG_CONF="${pkgs.pacman}/etc/makepkg.conf"
              case "$PS1" in
              "(fdcr-repo) "*) ;;
              *) export PS1="(fdcr-repo) $PS1" ;;
              esac
            '';
          };
        }
      );
    };
}
