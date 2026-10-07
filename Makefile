all: sign

.PHONY: sign
sign:
	@set -a; \
	[ -f .env ] && . ./.env; \
	set +a; \
	if [ -z "$$GPG_KEY_ID" ]; then \
		echo "Error: GPG_KEY_ID is not set"; \
		exit 1; \
	fi; \
	$(MAKE) repos GPG_KEY_ID="$$GPG_KEY_ID"

.PHONY: repos
repos: ubuntu-noble ubuntu-jammy centos-stream arch

.PHONY: ubuntu-noble
ubuntu-noble: scripts/build-apt.sh
	@SOURCE=./src/ubuntu-noble CODENAME=noble PUBLIC=./public/noble ./scripts/build-apt.sh

.PHONY: ubuntu-jammy
ubuntu-jammy: scripts/build-apt.sh
	@SOURCE=./src/ubuntu-jammy CODENAME=jammy PUBLIC=./public/jammy ./scripts/build-apt.sh

.PHONY: centos-stream
centos-stream: scripts/build-dnf.sh
	@./$<

.PHONY: arch
arch: scripts/build-pacman.sh
	@./$<

.PHONY: test
test: scripts/test-digest.sh
	@./$<

.PHONY: clean
clean:
	rm -rf public
