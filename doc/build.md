# Building repositories

Install Git LFS before cloning, then download the source files:

```sh
git lfs install
git clone https://github.com/tavocg/fdcr-repo.git
cd fdcr-repo
git lfs pull
```

The source ZIPs are listed in `.gitattributes`. Add new large files with
`git lfs track --filename PATH` before staging them.
Commit `.gitattributes` along with the files.

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

The build targets create separate repositories in `public/noble/`,
`public/jammy/`, `public/fedora/`, and `public/arch/`.

Source packages are organized by target distribution and release, rather than
by package format:

| Source directory | Target |
| --- | --- |
| `src/ubuntu-noble/` | Ubuntu 24.04 LTS (Noble Numbat), built as APT packages |
| `src/ubuntu-jammy/` | Ubuntu 22.04 LTS (Jammy Jellyfish), built as APT packages |
| `src/fedora/` | Fedora, built as RPM packages |
| `src/arch/` | Arch Linux rolling release, built as Pacman packages |

This allows distribution-specific package variants to coexist, such as a
separate `src/artix/` tree if an Arch package does not work on Artix.

```sh
gpg --armor --export "$GPG_KEY_ID" > public/fdcr.asc
```

[Back to README](../README.md)
