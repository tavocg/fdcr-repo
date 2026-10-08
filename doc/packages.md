## Paquetes

Configura primero el repositorio siguiendo el [README](../README.md).
Para instalar mediante Nix, consulta la [guía de Nix](nix.md).

### `idopte-p11`

Acceso a la tarjeta mediante PKCS#11.

**Ubuntu 24.04 y 26.04:** el paquete de `noble` conserva la ABI
`libxml2.so.2`. APT satisface la dependencia con `libxml2` del sistema cuando
está disponible, o con `libxml2-idopte-compat` en Ubuntu 26.04. Este último
instala la biblioteca en `/usr/lib/SCMiddleware/compat/`, sin reemplazar
`libxml2.so.16` ni registrar rutas globales con `ldconfig`.

La derivación Nix `idopte-p11-noble` prepara el árbol del `.deb` y añade
`$ORIGIN/compat` al `RUNPATH`
de `libdigidoc.so`, `libpodofo.so`, `libxmlsec1.so` y
`libxmlsec1-openssl.so`, conservando las rutas existentes. Si se instala el
paquete de compatibilidad, esa copia privada tiene prioridad sobre las rutas
predeterminadas del sistema.
La firma con tarjeta en las distribuciones de destino sigue pendiente de prueba.

| Distro       | Empaquetado | Probado |
|--------------|-------------|---------|
| Arch Linux   | arch        |         |
| Fedora 45    | fedora      |         |
| Fedora 44    | fedora      |         |
| Fedora 43    | fedora      |         |
| Ubuntu 26.04 | noble       |         |
| Ubuntu 24.04 | noble       |         |
| Ubuntu 22.04 | jammy       |         |
| Debian 13    | noble       |         |
| Debian 12    | noble       |         |
| NixOS 26.11  | nix         |         |

### `idopte-scmanager`

Interfaz gráfica de administración de Idopte.

| Distro       | Empaquetado | Probado |
|--------------|-------------|---------|
| Arch Linux   |             |         |
| Fedora 45    |             |         |
| Fedora 44    |             |         |
| Ubuntu 26.04 | noble       |         |
| Ubuntu 24.04 | noble       |         |
| Ubuntu 22.04 | jammy       |         |
| Debian 13    | noble       |         |
| Debian 12    | noble       |         |
| NixOS 26.11  | nix         |         |

### `bccr-gaudi`

Agente GAUDI del BCCR con Java/JavaFX incluido.

| Distro       | Empaquetado | Probado |
|--------------|-------------|---------|
| Arch Linux   | arch        |         |
| Fedora 45    | fedora      |         |
| Fedora 44    | fedora      |         |
| Ubuntu 26.04 | noble       |         |
| Ubuntu 24.04 | noble       |         |
| Ubuntu 22.04 | jammy       |         |
| Debian 13    | noble       |         |
| Debian 12    | noble       |         |
| NixOS 26.11  | nix         |         |

### `bccr-certs`

Certificados del proveedor y conjuntos PEM.

| Distro       | Empaquetado | Probado |
|--------------|-------------|---------|
| Arch Linux   | arch        |         |
| Fedora 45    | fedora      |         |
| Fedora 44    | fedora      |         |
| Ubuntu 26.04 | noble       |         |
| Ubuntu 24.04 | noble       |         |
| Ubuntu 22.04 | jammy       |         |
| Debian 13    | noble       |         |
| Debian 12    | noble       |         |
| NixOS 26.11  | nix         |         |

### `firmador`

Firma de documentos con Firmador Libre.

| Distro       | Empaquetado | Probado |
|--------------|-------------|---------|
| Arch Linux   | arch        |         |
| Fedora 45    | fedora      |         |
| Fedora 44    | fedora      |         |
| Ubuntu 26.04 | noble       |         |
| Ubuntu 24.04 | noble       |         |
| Ubuntu 22.04 | jammy       |         |
| Debian 13    | noble       |         |
| Debian 12    | noble       |         |
| NixOS 26.11  | nix         |         |

### `libxml2-idopte-compat`

Biblioteca privada para Idopte, construida únicamente en `noble`. Reempaqueta
[libxml2 de Debian 13](https://packages.debian.org/trixie/libxml2), versión
`2.12.7+dfsg+really2.9.14-2.1+deb13u3`, y conserva sus avisos de licencia y
changelog. Requiere `libc6 >= 2.38`, `liblzma5` y `zlib1g`.

La URL y el SHA-256 están fijados en
[`noble.nix`](../nix/packages/libxml2-idopte-compat/noble.nix).
Para incorporar actualizaciones de seguridad de Debian, se deben actualizar
la fuente, el hash y la versión del paquete de compatibilidad, y reconstruir
el repositorio. APT puede actualizar este paquete sin actualizar Idopte.
