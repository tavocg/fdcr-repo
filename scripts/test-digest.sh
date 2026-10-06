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
# Arguments: directory and optional exclude-file path. Prints a whitespace-separated list.
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

    found_file=
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

      if [ "$found_file" ]; then
        printf ' %s' "$line"
      else
        found_file=1
        printf '%s' "$line"
      fi
    done
  )
}

# Calculate the unique SHA-256 digests for a whitespace-separated list of files.
# Arguments: file list and directory in which those relative paths are located.
sha256sums() {
  file_list="$1"
  dir_path="${2:-.}"

  (
    cd "$dir_path"

    sums=
    for file in $file_list; do
      sum=$(sha256sum "$file")
      sum=${sum%% *}
      sums=$(append_once "$sums" "$sum")
    done

    printf '%s\n' "$sums"
  )
}

# Extract a supported archive into a destination directory.
# Arguments: archive path and destination directory. Returns nonzero on failure.
extract_archive() {
  archive="$1"
  destination="$2"

  case "$archive" in
  *.tar.bz2|*.tbz2) tar -xjf "$archive" -C "$destination" ;;
  *.tar.zst) tar --zstd -xf "$archive" -C "$destination" ;;
  *.tar.xz) tar -xJf "$archive" -C "$destination" ;;
  *.tar.gz|*.tgz) tar -xzf "$archive" -C "$destination" ;;
  *.tar) tar -xf "$archive" -C "$destination" ;;
  *.rar) (cd "$destination" && unrar x "$archive") ;;
  *.zip) unzip -q "$archive" -d "$destination" ;;
  *.deb) (cd "$destination" && ar x "$archive") ;;
  *.bz2) (cd "$destination" && bunzip2 -k "$archive") ;;
  *.7z) 7z x -y "-o$destination" "$archive" >/dev/null ;;
  *.gz) (cd "$destination" && gzip -dk "$archive") ;;
  *.xz) (cd "$destination" && xz -dk "$archive") ;;
  *.Z) (cd "$destination" && uncompress -c "$archive" >"$destination/${archive##*/}") ;;
  *) printf 'Unsupported archive: %s\n' "$archive" >&2; return 1 ;;
  esac
}

# Check that every digest in the untrusted list exists in the trusted list.
# Arguments: trusted digest list and untrusted digest list.
cmp_sum() {
  trusted="$1"
  untrusted="$2"

  for digest in $untrusted; do
    case " $trusted " in
    *" $digest "*) ;;
    *) return 1 ;;
    esac
  done

  return 0
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

# Compare a package directory's file digests against its sibling source archive.
# Argument: package directory. Uses a sibling .exclude file when present.
verify_package() {
  package_dir="$1"
  package_name=${package_dir##*/}
  package_parent=${package_dir%/*}
  exclude="$package_parent/$package_name.exclude"
  archive=

  for candidate in "$package_parent/$package_name".source.*; do
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

  package_files=$(file_list "$package_dir" "$exclude")
  source_files=$(file_list "$temp_dir" "")
  package_sums=$(sha256sums "$package_files" "$package_dir")
  source_sums=$(sha256sums "$source_files" "$temp_dir")

  if ! cmp_sum "$source_sums" "$package_sums"; then
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
