{
  description = "Development shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
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
              rpm
              dpkg
              createrepo_c
              apt
              gnupg
              binutils
              git-lfs
            ];

            shellHook = ''
              case "$PS1" in
              "(sfd) "*) ;;
              *) export PS1="(sfd) $PS1" ;;
              esac
            '';
          };
        }
      );
    };
}
