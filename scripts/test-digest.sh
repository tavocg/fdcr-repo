#!/bin/sh

set -eu

: "${SOURCE:=./src}"

# Print a whitespace-separated list with $2 appended only if it is not present.
# Arguments: existing list and value to append. Output: updated list on stdout.
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
  if [ -n "$exclude_file_path" ]; then
    exclude=1
  fi

  base_dir=$(pwd)
  (
    cd "$dir_path"

    found_file=
    find . | while IFS= read -r line; do
      if [ -d "$line" ]; then
        continue
      fi

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
  # We must check that all sources exist on target.
  source="$1" # 4da34... 90c41...
  target="$2" # 4da34... 90c41... f3d7f...

  set -- $target

  for trusted; do
    new_source=
    removed=

    for digest in $source; do
      if [ -z "$removed" ] && [ "$digest" = "$trusted" ]; then
        removed=1
        continue
      fi

      new_source=$(append_once "$new_source" "$digest")
    done

    source="$new_source"

    [ -z "$source" ] && return 0
  done

  return 1
}

files "src/apt/fdcr-middleware-idopte_6.23.50.5-1_amd64" "src/apt/fdcr-middleware-idopte_6.23.50.5-1_amd64.exclude"
