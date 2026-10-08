all: verify-checksums public

NIX_FLAKE ?= .

.PHONY: public
public: public/install.sh public/fdcr.asc public/noble public/jammy public/fedora public/arch

public/install.sh: scripts/install-repo.sh
	@mkdir -p "$(@D)"
	cp "$<" "$@"

.PHONY: public/fdcr.asc
public/fdcr.asc:
	@mkdir -p "$(@D)"
	@set -a; \
	[ -f .env ] && . ./.env; \
	set +a; \
	if [ -n "$$GPG_KEY_ID" ]; then \
		gpg --armor --export "$$GPG_KEY_ID" > "$@"; \
	fi

.PHONY: public/noble
public/noble: scripts/build-apt.sh src/noble/firmador_2.0.0-1_all src/noble/libxml2-idopte-compat_2.9.14+deb13u3-1_amd64
	@set -eu; \
	output=$$(nix build --no-link --print-out-paths '$(NIX_FLAKE)#idopte-p11-noble'); \
	staging_dir=$$(mktemp -d "$${TMPDIR:-/tmp}/fdcr-noble.XXXXXX"); \
	trap 'rm -rf "$$staging_dir"' EXIT HUP INT TERM; \
	for pkg_dir in "$$PWD"/src/noble/*; do \
		[ -d "$$pkg_dir" ] || continue; \
		case "$${pkg_dir##*/}" in idopte-p11_*) continue ;; esac; \
		ln -s "$$pkg_dir" "$$staging_dir/$${pkg_dir##*/}"; \
	done; \
	mkdir -p "$$staging_dir/idopte-p11_6.23.50.5-1_amd64"; \
	cp -R --preserve=mode,timestamps "$$output/." "$$staging_dir/idopte-p11_6.23.50.5-1_amd64/"; \
	chmod -R u+w "$$staging_dir/idopte-p11_6.23.50.5-1_amd64"; \
	GPG_KEY_ID="$$GPG_KEY_ID" SOURCE="$$staging_dir" CODENAME=noble PUBLIC=./public/noble ./scripts/build-apt.sh

.PHONY: src/noble/libxml2-idopte-compat_2.9.14+deb13u3-1_amd64
src/noble/libxml2-idopte-compat_2.9.14+deb13u3-1_amd64:
	@set -eu; \
	output=$$(nix build --no-link --print-out-paths '$(NIX_FLAKE)#libxml2-idopte-compat-noble'); \
	mkdir -p "$@"; \
	cp -R --preserve=mode,timestamps "$$output/." "$@/"; \
	chmod -R u+w "$@"

.PHONY: src/noble/firmador_2.0.0-1_all
src/noble/firmador_2.0.0-1_all:
	@set -eu; \
	output=$$(nix build --no-link --print-out-paths '$(NIX_FLAKE)#"firmador-noble-2.0.0-1"'); \
	mkdir -p "$@"; \
	cp -R --preserve=mode,timestamps "$$output/." "$@/"; \
	chmod -R u+w "$@"

.PHONY: public/jammy
public/jammy: scripts/build-apt.sh src/jammy/firmador_2.0.0-1_all src/jammy/bccr-certs_2026.08-1_all
	@GPG_KEY_ID="$$GPG_KEY_ID" SOURCE=./src/jammy CODENAME=jammy PUBLIC=./public/jammy ./scripts/build-apt.sh

.PHONY: src/jammy/firmador_2.0.0-1_all
src/jammy/firmador_2.0.0-1_all:
	@set -eu; \
	output=$$(nix build --no-link --print-out-paths '$(NIX_FLAKE)#"firmador-jammy-2.0.0-1"'); \
	mkdir -p "$@"; \
	cp -R --preserve=mode,timestamps "$$output/." "$@/"; \
	chmod -R u+w "$@"

.PHONY: src/jammy/bccr-certs_2026.08-1_all
src/jammy/bccr-certs_2026.08-1_all:
	@set -eu; \
	output=$$(nix build --no-link --print-out-paths '$(NIX_FLAKE)#"bccr-certs-jammy-2026.08-1"'); \
	mkdir -p "$@"; \
	cp -R --preserve=mode,timestamps "$$output/." "$@/"; \
	chmod -R u+w "$@"

.PHONY: public/fedora
public/fedora: scripts/build-dnf.sh src/fedora/firmador-2.0.0-1 src/fedora/bccr-certs-2026.08-1
	@GPG_KEY_ID="$$GPG_KEY_ID" ./$<

.PHONY: src/fedora/firmador-2.0.0-1
src/fedora/firmador-2.0.0-1:
	@set -eu; \
	output=$$(nix build --no-link --print-out-paths '$(NIX_FLAKE)#"firmador-fedora-2.0.0-1"'); \
	mkdir -p "$@"; \
	cp -R --preserve=mode,timestamps "$$output/rootfs" "$@/"; \
	chmod -R u+w "$@"

.PHONY: src/fedora/bccr-certs-2026.08-1
src/fedora/bccr-certs-2026.08-1:
	@set -eu; \
	output=$$(nix build --no-link --print-out-paths '$(NIX_FLAKE)#"bccr-certs-fedora-2026.08-1"'); \
	mkdir -p "$@/rootfs"; \
	cp -R --preserve=mode,timestamps "$$output/rootfs/." "$@/rootfs/"; \
	chmod -R u+w "$@"

.PHONY: public/arch
public/arch: scripts/build-pacman.sh src/arch/firmador-2.0.0-1 src/arch/bccr-certs-2026.08-1
	@GPG_KEY_ID="$$GPG_KEY_ID" ./$<

.PHONY: src/arch/firmador-2.0.0-1
src/arch/firmador-2.0.0-1:
	@set -eu; \
	output=$$(nix build --no-link --print-out-paths '$(NIX_FLAKE)#"firmador-arch-2.0.0-1"'); \
	mkdir -p "$@"; \
	cp -R --preserve=mode,timestamps "$$output/rootfs" "$@/"; \
	chmod -R u+w "$@"

.PHONY: src/arch/bccr-certs-2026.08-1
src/arch/bccr-certs-2026.08-1:
	@set -eu; \
	output=$$(nix build --no-link --print-out-paths '$(NIX_FLAKE)#"bccr-certs-arch-2026.08-1"'); \
	mkdir -p "$@/rootfs"; \
	cp -R --preserve=mode,timestamps "$$output/rootfs/." "$@/rootfs/"; \
	chmod -R u+w "$@"

.PHONY: verify-checksums
verify-checksums: scripts/verify-checksums.sh
	@./$<

.PHONY: clean
clean: clean/public

clean/public:
	rm -rf "public"
