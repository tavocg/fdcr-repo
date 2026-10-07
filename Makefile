all: verify-checksums public

.PHONY: public
public: public/fdcr.asc public/noble public/jammy public/fedora public/arch

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
public/noble: scripts/build-apt.sh
	@GPG_KEY_ID="$$GPG_KEY_ID" SOURCE=./src/ubuntu-noble CODENAME=noble PUBLIC=./public/noble ./scripts/build-apt.sh

.PHONY: public/jammy
public/jammy: scripts/build-apt.sh
	@GPG_KEY_ID="$$GPG_KEY_ID" SOURCE=./src/ubuntu-jammy CODENAME=jammy PUBLIC=./public/jammy ./scripts/build-apt.sh

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
