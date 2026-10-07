# Instalación

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
  sudo apt install fdcr-middleware-idopte
  ```

## Fedora

1. Instalar llave
  ```sh
  sudo curl -fsSLo /etc/pki/rpm-gpg/fdcr.asc https://tavocg.github.io/fdcr-repo/fdcr.asc
  ```
  ```sh
  sudo rpm --import /etc/pki/rpm-gpg/fdcr.asc
  ```

2. Instalar repositorio
  ```sh
  sudo tee /etc/yum.repos.d/fdcr.repo > /dev/null <<'INI'
  [fdcr]
  name=FDCR Repository
  baseurl=https://tavocg.github.io/fdcr-repo/centos-stream-9/
  enabled=1
  gpgcheck=0
  repo_gpgcheck=1
  gpgkey=file:///etc/pki/rpm-gpg/fdcr.asc
  INI
  ```

3. Refrescar cache
  ```sh
  sudo dnf makecache --refresh
  ```

4. Instalar paquetes
  ```sh
  sudo dnf install fdcr-middleware-idopte
  ```

## Arch

1. Instalar llave
  ```sh
  curl -fsSL https://example.com/fdcr.asc -o /tmp/fdcr.asc
  sudo pacman-key --add /tmp/fdcr.asc
  sudo pacman-key --finger "YOUR_SIGNING_KEY_ID"
  sudo pacman-key --lsign-key "YOUR_SIGNING_KEY_ID"
  ```

2. Instalar repositorio
  Add this section to `/etc/pacman.conf`:
  ```ini
  [fdcr]
  SigLevel = Required
  Server = https://tavocg.github.io/fdcr-repo/arch/
  ```

3. Actualizar índice e instalar software
  ```sh
  sudo pacman -Syu fdcr-middleware-idopte
  ```
