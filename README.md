# fdcr-repo

Repositorio de dependencias para Firma Digital en Costa Rica

- [Construcción](doc/build.md)
- [Nix](doc/nix.md)
- [Otros paquetes](doc/packages.md)

## Instalación

### Ubuntu 24.04

1. Instalar llave
  ```sh
  sudo curl -fsSLo /usr/share/keyrings/fdcr.asc https://tavocg.github.io/fdcr-repo/fdcr.asc
  ```

2. Instalar repositorio
  ```sh
  echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/fdcr.asc] https://tavocg.github.io/fdcr-repo/noble noble main' | sudo tee /etc/apt/sources.list.d/fdcr.list
  ```

3. Refrescar índice
  ```sh
  sudo apt update
  ```

4. Instalar paquetes
  ```sh
  sudo apt install fdcr-middleware-idopte
  ```

### Fedora

1. Instalar llave
  ```sh
  curl -fsSLo /tmp/fdcr.asc https://tavocg.github.io/fdcr-repo/fdcr.asc
  sudo install -Dm644 /tmp/fdcr.asc /etc/pki/rpm-gpg/fdcr.asc
  rm -f /tmp/fdcr.asc
  sudo rpm --import /etc/pki/rpm-gpg/fdcr.asc
  ```

2. Instalar repositorio
  ```sh
  sudo tee /etc/yum.repos.d/fdcr.repo > /dev/null <<'INI'
  [fdcr]
  name=FDCR Repository
  baseurl=https://tavocg.github.io/fdcr-repo/fedora/
  enabled=1
  gpgcheck=0
  repo_gpgcheck=1
  gpgkey=file:///etc/pki/rpm-gpg/fdcr.asc
  INI
  ```

4. Instalar paquetes
  ```sh
  sudo dnf install fdcr-middleware-idopte
  ```

### Arch

1. Instalar llave
  ```sh
  curl -fsSL https://tavocg.github.io/fdcr-repo/fdcr.asc -o /tmp/fdcr.asc
  sudo pacman-key --add /tmp/fdcr.asc
  sudo pacman-key --lsign-key "$(gpg --show-keys --with-colons /tmp/fdcr.asc | sed '/fpr/!d;s/:$//;s/.*://')"
  rm -f /tmp/fdcr.asc
  ```

2. Instalar repositorio
  ```sh
  sudo tee -a /etc/pacman.conf > /dev/null <<'INI'

  [fdcr]
  SigLevel = Required
  Server = https://tavocg.github.io/fdcr-repo/arch/
  INI
  ```

3. Actualizar índice e instalar software
  ```sh
  sudo pacman -Syu fdcr-middleware-idopte
  ```
