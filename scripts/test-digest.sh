#!/bin/sh

set -eu

: "${SOURCE:=./src}"

# Append a value to a whitespace-separated list only if it is not already present.
# Arguments: current list and value to append. Prints the updated list.
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

# List regular files under a directory, omitting paths listed in an optional exclude file.
# Arguments: directory and optional exclude-file path. Prints one relative path per line.
file_list() {
  dir_path="$1"
  exclude_file_path="$2"

  if ! [ -d "$dir_path" ]; then
    return 1
  fi

  exclude=
  if [ -n "$exclude_file_path" ] && [ -f "$exclude_file_path" ]; then
    exclude=1
  fi

  base_dir=$(pwd)
  (
    cd "$dir_path"

    find . -type f | while IFS= read -r line; do
      ignored=
      if [ "$exclude" ]; then
        while IFS= read -r ignored_line; do
          if [ "$line" = "$ignored_line" ]; then
            ignored=1
            break
          fi
        done <"$base_dir/$exclude_file_path"
      fi

      if [ "$ignored" ]; then
        continue
      fi

      printf '%s\n' "$line"
    done
  )
}

# Calculate SHA-256 digests for a newline-separated list of files.
# Arguments: file list and directory in which those relative paths are located.
sha256sums() {
  file_list="$1"
  dir_path="${2:-.}"

  (
    cd "$dir_path"

    printf '%s\n' "$file_list" | while IFS= read -r file; do
      [ -n "$file" ] || continue
      sum=$(sha256sum "$file") || exit 1
      sum=${sum%% *}
      printf '%s\n' "$sum"
    done
  )
}

# Check whether a digest appears as a complete line in a newline-separated list.
# Arguments: digest to find and digest list.
contains_digest() {
  needle="$1"
  digest_list="$2"

  while IFS= read -r candidate; do
    [ "$candidate" = "$needle" ] && return 0
  done <<EOF
$digest_list
EOF

  return 1
}

# Extract a supported archive into a destination directory.
# Arguments: archive path and destination directory. Returns nonzero on failure.
extract_archive() {
  archive="$1"
  destination="$2"

  case "$archive" in
  *.tar.bz2 | *.tbz2) tar -xjf "$archive" -C "$destination" ;;
  *.tar.zst) tar --zstd -xf "$archive" -C "$destination" ;;
  *.tar.xz) tar -xJf "$archive" -C "$destination" ;;
  *.tar.gz | *.tgz) tar -xzf "$archive" -C "$destination" ;;
  *.tar) tar -xf "$archive" -C "$destination" ;;
  *.rar) (cd "$destination" && unrar x "$archive") ;;
  *.zip) unzip -q "$archive" -d "$destination" ;;
  *.deb) (cd "$destination" && ar x "$archive") ;;
  *.bz2) (cd "$destination" && bunzip2 -k "$archive") ;;
  *.7z) 7z x -y "-o$destination" "$archive" >/dev/null ;;
  *.gz) (cd "$destination" && gzip -dk "$archive") ;;
  *.xz) (cd "$destination" && xz -dk "$archive") ;;
  *.Z) (cd "$destination" && uncompress -c "$archive" >"$destination/${archive##*/}") ;;
  *)
    printf 'Unsupported archive: %s\n' "$archive" >&2
    return 1
    ;;
  esac
}

# Verify each package file's SHA-256 against the digests found in the extracted source.
# Arguments: package file list, package directory, and extracted source digest list.
verify_file_digests() {
  files="$1"
  directory="$2"
  trusted="$3"

  printf '%s\n' "$files" | while IFS= read -r file; do
    [ -n "$file" ] || continue
    digest=$(sha256sum "$directory/$file")
    digest=${digest%% *}
    if contains_digest "$digest" "$trusted"; then
      printf 'SHA-256 OK %s (%s)\n' "$file" "$digest"
    else
      printf 'SHA-256 missing from source: %s (%s)\n' "$file" "$digest" >&2
      return 1
    fi
  done
}

# Verify every .md5 checksum file found beneath SOURCE; stop on the first failure.
verify_md5_files() {
  find "$SOURCE" -type f -name '*.md5' -print | while IFS= read -r md5_file; do
    target_file=${md5_file%.md5}
    IFS=' ' read -r expected _ <"$md5_file"
    actual=$(md5sum "$target_file") || {
      printf 'MD5 verification failed: %s\n' "$md5_file" >&2
      exit 1
    }
    actual=${actual%% *}

    if [ -z "$expected" ] || [ "$expected" != "$actual" ]; then
      printf 'MD5 verification failed: %s\n' "$md5_file" >&2
      exit 1
    fi

    printf 'MD5 OK %s\n' "$target_file"
  done
}

# Compare a package directory's files against the matching source archive.
# Argument: package directory. Uses a sibling .exclude file when present.
verify_package() {
  package_dir="$1"
  package_name=${package_dir##*/}
  package_parent=${package_dir%/*}
  exclude="$package_parent/$package_name.exclude"
  payload_dir="$package_dir"
  archive=

  if [ -d "$package_dir/rootfs" ]; then
    payload_dir="$package_dir/rootfs"
  fi

  for candidate in "$SOURCE"/*/"$package_name".source.*; do
    [ -f "$candidate" ] || continue
    case "$candidate" in *.md5) continue ;; esac
    if [ -n "$archive" ]; then
      printf 'More than one source archive for %s\n' "$package_dir" >&2
      return 1
    fi
    archive="$candidate"
  done

  if [ -z "$archive" ]; then
    printf 'No source archive found for %s\n' "$package_dir" >&2
    return 1
  fi

  temp_dir=$(mktemp -d "${TMPDIR:-/tmp}/test-digest.XXXXXX")
  if ! extract_archive "$archive" "$temp_dir"; then
    rm -rf "$temp_dir"
    return 1
  fi

  package_files=$(file_list "$payload_dir" "$exclude")
  source_files=$(file_list "$temp_dir" "")
  source_sums=$(sha256sums "$source_files" "$temp_dir")

  if ! verify_file_digests "$package_files" "$payload_dir" "$source_sums"; then
    printf 'Package files do not match source archive: %s\n' "$package_dir" >&2
    rm -rf "$temp_dir"
    return 1
  fi

  printf 'OK %s\n' "$package_dir"
  rm -rf "$temp_dir"
}

main() {
  # First confirm each source archive against its adjacent MD5 checksum.
  verify_md5_files

  # Then check each package directory directly beneath a package manager directory.
  find "$SOURCE" -mindepth 2 -maxdepth 2 -type d -print | while IFS= read -r package_dir; do
    verify_package "$package_dir"
  done
}

main "$@"
