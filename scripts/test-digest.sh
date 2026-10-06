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

files() {
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

cmp_sum() {
  source="$1"
  target="$2"

  for digest in $source; do
    case " $target " in
    *" $digest "*) ;;
    *) return 1 ;;
    esac
  done

  return 0
}

files \
  "src/apt/fdcr-middleware-idopte_6.23.50.5-1_amd64" \
  "src/apt/fdcr-middleware-idopte_6.23.50.5-1_amd64.exclude"
