#!/bin/sh

# $@ = paths
_tree()
{
  if [ $# -gt 0 ]
  then
    fulltree=$(decrypt | tar -tf - 2>/dev/null) || exit $?;

    for N
    do
      [ $# -gt 1 ] && echo "> $N:"
      echo "$fulltree" | grep "^$(escape_chars "$N")" | sed "s|^$N||g;s|^/||g;/\/$/d;/^$/d"
    done

  else
    { decrypt | tar -tf - 2>/dev/null || exit $?; } | sed '/\/$/d ; /^$/d'
  fi
}

# $@ = paths
get()
{
  [ $# -lt 1 ] && return 1
  __NOPACK=y archive_exec sh -c '#LXSH_PARSE_MINIFY
  for N
  do
    (
      cat "$N" 2>/dev/null && exit 0
      [ -d "$1" ] && cat "$N/default" 2>/dev/null && exit 0
      exit 1
    ) || { echo "$N: not found" >&2 && exit 1; }
  done
  ' zpass "$@"
}

# $1 = path
copy()
{
  copy_check || return $?
  { get "$1" || return $?; } | remove_trailing_newline | clipboard && clipboard_clear "$ZPASS_CLIPBOARD_TIME"
}

# $@ = path
new()
{
  [ $# -lt 1 ] && return 1
  archive_exec sh -c '#LXSH_PARSE_MINIFY
    len=$1
    rset=$2
    shift 2
    for N
    do
      mkdir -p "$(dirname "$N")" || exit $?
      { tr -cd "$rset" < /dev/urandom | head -c$len && echo; } > "$N" || exit $?
    done
  ' zpass "$ZPASS_RAND_LEN" "$ZPASS_RAND_SET" "$@"
}

# $1 = path , $@ = value
_set()
{
  [ $# -lt 1 ] && return 1
  ref=$1
  shift 1
  archive_exec sh -c '#LXSH_PARSE_MINIFY
    mkdir -p "$(dirname "$1")" && printf "%s\n" "$2" > "$1"
  ' zpass "$ref" "$*"
}

add()
{
  [ $# -lt 1 ] && return 1
  archive_exec true # prompt for the key
  for N
  do
    val=$(prompt_password "New value for $N") || return $?
    _set "$N" "$val" || return $?
  done
}

fileset()
{
  contents=$(cat "$2") || return $?
  _set "$1" "$contents"
}

move()
{
  [ $# -lt 1 ] && return 1
  archive_exec sh -c '#LXSH_PARSE_MINIFY
    set -e
    for last ; do true ; done
    if [ "$#" -gt 2 ] ; then
      mkdir -p "$last"
    else
      mkdir -p "$(dirname "$last")"
    fi
    mv -f -- "$@"
  ' zpass "$@"
}

cond_copy() {
  if [ "$ZPASS_COPY_ON_EDIT" = true ] ; then
    copy "$1"
  fi
}
