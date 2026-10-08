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

# Package preparation is discovered by each repository builder.
export NIX_FLAKE
export SKIP_NIX

.PHONY: public/noble
public/noble: scripts/build-apt.sh
	@SOURCE=./src/noble CODENAME=noble PUBLIC=./public/noble ./$<

.PHONY: public/jammy
public/jammy: scripts/build-apt.sh
	@SOURCE=./src/jammy CODENAME=jammy PUBLIC=./public/jammy ./$<

.PHONY: public/fedora
public/fedora: scripts/build-dnf.sh
	@./$<

.PHONY: public/arch
public/arch: scripts/build-pacman.sh
	@./$<

.PHONY: verify-checksums
verify-checksums: scripts/verify-checksums.sh
	@./$<

.PHONY: clean
clean: clean/public

clean/public:
	rm -rf "public"
