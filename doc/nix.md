# Nix

Agrega el input al flake:

```nix
fdcr = {
  url = "github:tavocg/fdcr-repo";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

## NixOS

Importa el módulo y habilita los componentes que necesites (`x86_64-linux`):

```nix
{
  imports = [ inputs.fdcr.nixosModules.fdcr ];
  services.fdcr = {
    enable = true;
    gaudi.enable = true;
    middleware.enable = true;
    certificates.enable = true;
    scmanager.enable = true;
  };
}
```

Aplica la configuración con `sudo nixos-rebuild switch` y abre GAUDI con
`agente-gaudi` o SCManager con `SCManager`.

## Paquetes individuales

Agrega los paquetes a `environment.systemPackages` o `home.packages`:

```nix
let
  fdcr = inputs.fdcr.packages.${pkgs.stdenv.hostPlatform.system};
in
[
  fdcr.fdcr-middleware-idopte
  fdcr.fdcr-scmanager
  fdcr.fdcr-bccr-gaudi
  fdcr.fdcr-bccr-certs
  fdcr.firmador
]
```

También puedes instalarlos con `nix profile add`, por ejemplo:

```sh
nix profile add github:tavocg/fdcr-repo#firmador
```

## Firmador Libre

```sh
firmador                                 # Interfaz gráfica
firmador -dshell                         # Consola interactiva
firmador -dargs original.pdf firmado.pdf
LIBASEP11=/ruta/al/driver.so firmador     # Driver PKCS#11
```

Para usar Idopte, agrega este paquete a tu configuración:

```nix
let
  fdcr = inputs.fdcr.packages.${pkgs.stdenv.hostPlatform.system};
in
fdcr.firmador.override {
  pkcs11Module = "${fdcr.fdcr-middleware-idopte}/lib/SCMiddleware/libidop11.so";
}
```

Habilita `services.pcscd.enable = true;` si no usas el módulo FDCR.
Para la versión 1.9.8, selecciona `firmador_1_9` en lugar de `firmador`.

[Guía de uso de Firmador](https://codeberg.org/firmador/firmador/src/branch/master/preguntas-frecuentes.md)

[Volver al README](../README.md)
