# Nix

Add the flake input:

```nix
fdcr = {
  url = "github:tavocg/fdcr-repo";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Use in `environment.systemPackages` or `home.packages` (`x86_64-linux`):

```nix
inputs.fdcr.packages.${pkgs.stdenv.hostPlatform.system}.fdcr-middleware-idopte
# Or select a specific version:
inputs.fdcr.packages.${pkgs.stdenv.hostPlatform.system}."fdcr-middleware-idopte-6.23.50.5-1"
```

`default` is an alias for the latest middleware. To install directly:

```sh
nix profile add github:tavocg/fdcr-repo#fdcr-middleware-idopte
# Or select a specific version:
nix profile add 'github:tavocg/fdcr-repo#"fdcr-middleware-idopte-6.23.50.5-1"'
```

## Firmador Libre

Use `inputs.fdcr.packages.${pkgs.stdenv.hostPlatform.system}.firmador`, or install directly:

```sh
nix profile add github:tavocg/fdcr-repo#firmador
firmador                              # Desktop interface
firmador -dshell                      # Interactive console
firmador -dargs original.pdf firmado.pdf
LIBASEP11=/path/to/driver.so firmador  # Select a PKCS#11 driver
```

`firmador` selects `firmador_2_0` (2.0.0). To select `firmador_1_9` (1.9.8):

```nix
inputs.fdcr.packages.${pkgs.stdenv.hostPlatform.system}.firmador_1_9
```

```sh
nix profile add github:tavocg/fdcr-repo#firmador_1_9
```

Built from source with Maven; includes a desktop launcher for `firmador:` links.
No proprietary middleware is included by default. To opt into Idopte at your own risk:

```nix
let
  fdcr = inputs.fdcr.packages.${pkgs.stdenv.hostPlatform.system};
in
fdcr.firmador.override {
  pkcs11Module = "${fdcr.fdcr-middleware-idopte}/lib/SCMiddleware/libidop11.so";
}
```

`pkcs11Module` accepts any compatible driver path; `LIBASEP11` takes precedence.
Version 1.9.8 includes a backport of `LIBASEP11` support.
For card readers on NixOS, enable `services.pcscd.enable = true;`.
See the [upstream usage guide](https://codeberg.org/firmador/firmador/src/branch/master/preguntas-frecuentes.md).

[Back to README](../README.md)
