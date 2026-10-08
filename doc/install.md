# Instalación manual

Instrucciones para configurar el repositorio e instalar los paquetes de Firma Digital.

[Volver al README](../README.md)

## Ubuntu 24.04

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
  sudo apt install idopte-p11
  ```

## Fedora

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
  gpgcheck=1
  repo_gpgcheck=0
  gpgkey=file:///etc/pki/rpm-gpg/fdcr.asc
  INI
  ```

3. Instalar paquetes
  ```sh
  sudo dnf install idopte-p11
  ```

## Arch

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
  sudo pacman -Syu idopte-p11
  ```
