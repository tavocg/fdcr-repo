# fdcr - Firma Digital Costa Rica

## Building repositories

Build all repositories with the signing key available in your GPG keyring:

```sh
GPG_KEY_ID="YOUR_SIGNING_KEY_ID"
GPG_KEY_ID="$GPG_KEY_ID" ./scripts/build-apt.sh
GPG_KEY_ID="$GPG_KEY_ID" ./scripts/build-rpm.sh
GPG_KEY_ID="$GPG_KEY_ID" ./scripts/build-pacman.sh
```

The scripts create `public/apt/`, `public/rpm/`, and `public/pacman/`.

```sh
gpg --armor --export "$GPG_KEY_ID" > public/fdcr.asc
```

## Clients

If `public/` is published at `https://example.com/`.

### APT clients (Debian and Ubuntu)

1. Install key
  ```sh
  sudo curl -fsSLo /usr/share/keyrings/fdcr.asc https://example.com/fdcr.asc
  ```

2. Install repo
  ```sh
  echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/fdcr.asc] https://example.com/apt stable main' | sudo tee /etc/apt/sources.list.d/fdcr.list
  ```

3. Update sources
  ```sh
  sudo apt update
  ```

4. Install software
  ```sh
  sudo apt install fdcr-middleware-idopte
  ```

### RPM clients (Fedora, RHEL, and compatible systems)

1. Install key
  ```sh
  sudo curl -fsSLo /etc/pki/rpm-gpg/fdcr.asc https://example.com/fdcr.asc
  sudo rpm --import /etc/pki/rpm-gpg/fdcr.asc
  ```

2. Install repo
  ```sh
  sudo tee /etc/yum.repos.d/fdcr.repo > /dev/null <<'INI'
  [fdcr]
  name=Soporte Firma Digital
  baseurl=https://example.com/rpm/
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


### Pacman clients (Arch Linux and compatible systems)

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
  Server = https://example.com/pacman/
  ```

3. Update sources and install software
  ```sh
  sudo pacman -Syu fdcr-middleware-idopte
  ```
