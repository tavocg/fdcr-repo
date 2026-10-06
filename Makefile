all: apt dnf pacman

.PHONY: apt
apt: scripts/build-apt.sh
	@./$<

.PHONY: dnf
dnf: scripts/build-dnf.sh
	@./$<

.PHONY: pacman
pacman: scripts/build-pacman.sh
	@./$<

.PHONY: clean
clean:
	rm -rf public
