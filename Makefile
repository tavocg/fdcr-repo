all: apt rpm pacman

.PHONY: apt
apt: scripts/build-apt.sh
	@./$<

.PHONY: rpm
rpm: scripts/build-rpm.sh
	@./$<

.PHONY: pacman
pacman: scripts/build-pacman.sh
	@./$<

.PHONY: clean
clean:
	rm -rf public
