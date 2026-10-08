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

Build all repositories with the signing key available in your GPG keyring. The
repository builders discover package preparation scripts and run Nix by default:

```sh
GPG_KEY_ID="YOUR_SIGNING_KEY_ID" make all
```

The build targets create separate repositories in `public/noble/`,
`public/jammy/`, `public/fedora/`, and `public/arch/`.

| Source directory | Target |
| --- | --- |
| `src/noble/` | Ubuntu 24.04 LTS (Noble Numbat), built as APT packages |
| `src/jammy/` | Ubuntu 22.04 LTS (Jammy Jellyfish), built as APT packages |
| `src/fedora/` | Fedora, built as RPM packages |
| `src/arch/` | Arch Linux rolling release, built as Pacman packages |

This allows distribution-specific package variants to coexist, such as a
separate `src/artix/` tree if an Arch package does not work on Artix.

```sh
gpg --armor --export "$GPG_KEY_ID" > public/fdcr.asc
```

[Back to README](../README.md)

## Package preparation and Nix

Each package that requires Nix has an adjacent `<package-directory>.build.sh`.
These scripts are the inventory of generated packages; a directory without one
is packaged directly. This applies equally to APT, RPM and Pacman builds,
whether invoked through Make or directly.

```sh
make all                      # Prepare Nix packages and build all repositories
SKIP_NIX=1 make all           # Omit every package with a .build.sh hook
SKIP_NIX=1 make public/noble  # Same policy for a single repository
```

`SKIP_NIX` accepts `0` (default) or `1`. Skipped packages are not prepared or
packaged, even if a generated payload already exists locally. Previously
published versions of those packages and their signatures are removed from
the selected output repository by matching package metadata. Repository
indexes are regenerated, including an empty index if all packages are skipped.
Other packages may still depend on an omitted package: this option controls
repository contents, not dependency closure.

A Nix or preparation failure aborts the build; there is no fallback to old
payloads. These builds modify local output directories and are not atomic
publication transactions. Publish only after a successful build.

### Adding a generated package

Add an adjacent POSIX shell script. Its `--name` mode must print the exact
binary package name without building anything (used to remove old artifacts).
Its normal mode receives absolute source and empty destination directory paths.
It must prepare the complete package tree there and return nonzero on failure.
Hooks are invoked using `sh` and are trusted repository code.

```sh
#!/bin/sh
set -eu
if [ "${1:-}" = --name ]; then
  printf '%s\n' 'my-package'
  exit 0
fi
. "$(dirname "$0")/../../scripts/package-build.sh"
prepare_nix_tree 'my-package-noble' "$1" "$2" 'tree'
```

`prepare_nix_tree` runs `nix build`, preserves modes and timestamps when copying,
and makes the temporary tree writable for packaging. `tree` uses the complete
Nix output; `rootfs` combines its `rootfs/` with the source `.spec`, `PKGBUILD`
and `.install` recipes, excluding stale generated payloads. Extra package steps
can follow the helper call. Keep content transformations such as `patchelf` in
the derivation for reproducibility.

`NIX_FLAKE` defaults to `.` and can select another flake. For local development
with new files not yet tracked by Git, use `NIX_FLAKE=path:.`. All invocations
should start at the repository root. Temporary package trees are removed on
exit; generated content is no longer copied back into `src/`.
