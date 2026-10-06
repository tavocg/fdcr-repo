#!/bin/sh

set -eu

: "${SOURCE:=./src}"

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

sha256sums() {
  file_list="$1"
  dir_path="${2:-.}"

  (
    cd "$dir_path"

    sums=
    for file in $file_list; do
      sum=$(sha256sum "$file" | awk '{print $1}')
      sums=$(append_once "$sums" "$sum")
    done

    printf '%s\n' "$sums"
  )
}

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

dir="src/apt/fdcr-middleware-idopte_6.23.50.5-1_amd64"
exclude="src/apt/fdcr-middleware-idopte_6.23.50.5-1_amd64.exclude"

files="$(file_list "$dir" "$exclude")"

sums="$(sha256sums "$files" "$dir")"

printf '%s\n' "$sums"
