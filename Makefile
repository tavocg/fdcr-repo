all: ubuntu-noble ubuntu-jammy centos-stream arch

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
