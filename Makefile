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
public/noble: scripts/build-apt.sh src/noble/firmador_2.0.0-1_all
	@GPG_KEY_ID="$$GPG_KEY_ID" SOURCE=./src/noble CODENAME=noble PUBLIC=./public/noble ./scripts/build-apt.sh

.PHONY: src/noble/firmador_2.0.0-1_all
src/noble/firmador_2.0.0-1_all:
	@set -eu; \
	output=$$(nix build --no-link --print-out-paths '$(NIX_FLAKE)#"firmador-noble-2.0.0-1"'); \
	mkdir -p "$@"; \
	cp -R --preserve=mode,timestamps "$$output/." "$@/"; \
	chmod -R u+w "$@"

.PHONY: public/jammy
public/jammy: scripts/build-apt.sh src/jammy/firmador_2.0.0-1_all
	@GPG_KEY_ID="$$GPG_KEY_ID" SOURCE=./src/jammy CODENAME=jammy PUBLIC=./public/jammy ./scripts/build-apt.sh

.PHONY: src/jammy/firmador_2.0.0-1_all
src/jammy/firmador_2.0.0-1_all:
	@set -eu; \
	output=$$(nix build --no-link --print-out-paths '$(NIX_FLAKE)#"firmador-jammy-2.0.0-1"'); \
	mkdir -p "$@"; \
	cp -R --preserve=mode,timestamps "$$output/." "$@/"; \
	chmod -R u+w "$@"

.PHONY: public/fedora
public/fedora: scripts/build-dnf.sh
	@GPG_KEY_ID="$$GPG_KEY_ID" ./$<

.PHONY: public/arch
public/arch: scripts/build-pacman.sh
	@GPG_KEY_ID="$$GPG_KEY_ID" ./$<

.PHONY: verify-checksums
verify-checksums: scripts/verify-checksums.sh
	@./$<

.PHONY: clean
clean: clean/public

clean/public:
	rm -rf "public"
