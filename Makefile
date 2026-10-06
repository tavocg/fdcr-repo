all: ubuntu centos-stream arch

.PHONY: ubuntu
ubuntu: scripts/build-ubuntu.sh
	@./$<

.PHONY: centos-stream
centos-stream: scripts/build-centos-stream.sh
	@./$<

.PHONY: arch
arch: scripts/build-arch.sh
	@./$<

.PHONY: test
test: scripts/test-digest.sh
	@./$<

.PHONY: clean
clean:
	rm -rf public
