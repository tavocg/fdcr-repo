# Clients

## Ubuntu 24.04

1. Install key
  ```sh
  sudo curl -fsSLo /usr/share/keyrings/fdcr.asc https://tavocg.github.io/fdcr-repo/fdcr.asc
  ```

2. Install repo
  ```sh
  echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/fdcr.asc] https://tavocg.github.io/fdcr-repo/noble noble main' | sudo tee /etc/apt/sources.list.d/fdcr.list
  ```

3. Update sources
  ```sh
  sudo apt update
  ```

4. Install software
  ```sh
  sudo apt install fdcr-middleware-idopte
  ```

## Fedora

1. Install key
  ```sh
  sudo curl -fsSLo /etc/pki/rpm-gpg/fdcr.asc https://tavocg.github.io/fdcr-repo/fdcr.asc
  ```
  ```sh
  sudo rpm --import /etc/pki/rpm-gpg/fdcr.asc
  ```

2. Install repo
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

3. Refresh cache
  ```sh
  sudo dnf makecache --refresh
  ```

4. Install software
  ```sh
  sudo dnf install fdcr-middleware-idopte
  ```

## Arch

1. Install key
  ```sh
  curl -fsSL https://example.com/fdcr.asc -o /tmp/fdcr.asc
  sudo pacman-key --add /tmp/fdcr.asc
  sudo pacman-key --finger "YOUR_SIGNING_KEY_ID"
  sudo pacman-key --lsign-key "YOUR_SIGNING_KEY_ID"
  ```

2. Install repo
  Add this section to `/etc/pacman.conf`:
  ```ini
  [fdcr]
  SigLevel = Required
  Server = https://tavocg.github.io/fdcr-repo/arch/
  ```

3. Update sources and install software
  ```sh
  sudo pacman -Syu fdcr-middleware-idopte
  ```

[Back to README](../README.md)
