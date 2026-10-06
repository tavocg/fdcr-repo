#!/bin/sh
set -u

: "${ORIGIN:=Soporte Firma Digital}"
: "${LABEL:=Repositorio APT de Soporte Firma Digital}"
: "${SUITE:=stable}"
: "${CODENAME:=stable}"
: "${COMPONENT:=main}"
: "${DESCRIPTION:=Repositorio oficial de paquetes de Soporte Firma Digital}"
: "${SOURCE:=./src/apt}"
: "${PUBLIC:=./public/apt}"

# Optional.
# Example:
#   GPG_KEY_ID="ABCDEF1234567890" ./build-apt.sh
: "${GPG_KEY_ID:=}"

POOL="$PUBLIC/pool/$COMPONENT"            # ./public/apt/pool/main
DIST="$PUBLIC/dists/$CODENAME/$COMPONENT" # ./public/apt/dists/stable/main

mkdir -p "$POOL"
mkdir -p "$DIST"

# build_deb_package() builds a deb package given it's directory path with format:
# build_deb_package "/path/to/firmador_1.0.0_amd64"
# -> Creates `$POOL/firmador_1.0.0_amd64.deb`
build_deb_package() {
	pkg_dir="$1"

	if ! [ -d "$pkg_dir" ]; then
		return 1
	fi

	dpkg-deb --root-owner-group --build "$pkg_dir" "$POOL" >&2
}

append_once() {
	arr="$1"
	val="$2"

	case " $arr " in
	*" $val "*) ;;
	*)
		if [ -z "$arr" ]; then
			arr="$val"
		else
			arr="$arr $val"
		fi
		;;
	esac

	printf '%s\n' "$arr"
}

# build_deb_packages() builds al deb packages from sources in `$SOURCE`
build_deb_packages() {
	arches=""
	for pkg_dir in "$SOURCE"/*; do
		build_deb_package "$pkg_dir" || return "$?"
		arch="${pkg_dir##*_}"
		arches="$(append_once "$arches" "$arch")"
	done
	printf '%s' "$arches"
}

gen_arch_index() {
	arch="$1"

	dist_abs="$DIST/binary-$arch" # ./public/apt/dists/stable/main/binary-amd64
	mkdir -p "$dist_abs"

	pool="${POOL#"$PUBLIC"}"     # pool/main
	dist="${dist_abs#"$PUBLIC"}" # dists/stable/main/binary-amd64
	dist_index="$dist/Packages"  # dists/stable/main/binary-amd64/Packages

	(
		set -e
		cd "$PUBLIC"
		dpkg-scanpackages --arch "$arch" "$pool" >"$dist_index"
		gzip -9 -c "$dist_index" >"$dist_index.gz"
	)
}

gen_arch_indexes() {
	for arch in "$@"; do
		gen_arch_index "$arch"
	done
}

gen_release() {
	arches="$1"

	apt-ftparchive \
		-o "APT::FTPArchive::Release::Origin=$ORIGIN" \
		-o "APT::FTPArchive::Release::Label=$LABEL" \
		-o "APT::FTPArchive::Release::Suite=$SUITE" \
		-o "APT::FTPArchive::Release::Codename=$CODENAME" \
		-o "APT::FTPArchive::Release::Architectures=$arches" \
		-o "APT::FTPArchive::Release::Components=$COMPONENT" \
		-o "APT::FTPArchive::Release::Description=$DESCRIPTION" \
		release "$DIST" \
		>"$DIST/Release"
}

sign_release() {
	if [ -z "$GPG_KEY_ID" ]; then
		return 1
	fi

	dist="${DIST%"$COMPONENT"}"
	rm -f "$dist/InRelease" "$dist/Release.gpg"

	# Clearsigned Release file.
	# Modern APT clients normally prefer InRelease.
	gpg \
		--batch \
		--yes \
		--local-user "$GPG_KEY_ID" \
		--clearsign \
		--output "$dist/InRelease" \
		"$dist/Release"

	# Detached signature for compatibility.
	gpg \
		--batch \
		--yes \
		--local-user "$GPG_KEY_ID" \
		--armor \
		--detach-sign \
		--output "$dist/Release.gpg" \
		"$dist/Release"
}
