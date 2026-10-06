# fdcr-repo

Repositorio de dependencias para Firma Digital en Costa Rica

## Building repositories

Build all repositories with the signing key available in your GPG keyring:

```sh
GPG_KEY_ID="YOUR_SIGNING_KEY_ID"
GPG_KEY_ID="$GPG_KEY_ID" ./scripts/build-apt.sh
GPG_KEY_ID="$GPG_KEY_ID" ./scripts/build-dnf.sh
GPG_KEY_ID="$GPG_KEY_ID" ./scripts/build-pacman.sh
```

The `ubuntu-noble` and `ubuntu-jammy` Make targets call the same APT
builder with release-specific source trees and repository metadata. Additional
Ubuntu releases can use that builder with their own source directory, suite,
and codename.

The scripts create `public/apt/`, `public/dnf/`, and `public/pacman/`.

Source packages are organized by target distribution and release, rather than
by package format:

| Source directory | Target |
| --- | --- |
| `src/ubuntu-noble/` | Ubuntu 24.04 LTS (Noble Numbat), built as APT packages |
| `src/ubuntu-jammy/` | Ubuntu 22.04 LTS (Jammy Jellyfish), built as APT packages |
| `src/centos-stream-9/` | CentOS Stream 9, built as RPM packages |
| `src/arch/` | Arch Linux rolling release, built as Pacman packages |

This allows distribution-specific package variants to coexist, such as a
separate `src/artix/` tree if an Arch package does not work on Artix.

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
  echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/fdcr.asc] https://example.com/apt noble main' | sudo tee /etc/apt/sources.list.d/fdcr.list
  ```

3. Update sources
  ```sh
  sudo apt update
  ```

4. Install software
  ```sh
  sudo apt install fdcr-middleware-idopte
  ```

### DNF clients (Fedora, RHEL, and compatible systems)

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
  baseurl=https://example.com/dnf/
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
