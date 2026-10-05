all: apt

.PHONY: apt
apt: scripts/build-apt.sh
	./$<
