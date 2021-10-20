#!/bin/lxsh

unset archive_tmpdir tmpfile
_stop() {
  stty echo
  rm -rf "$archive_tmpdir" "$tmpfile"
}

[ "$DEBUG" = true ] && set -x

%include util.sh config.sh *.sh

## pre exec

clean_cache 2>/dev/null
[ $# -lt 1 ] && usage && exit 1

arg=$1
shift 1

## exec

case $arg in
  -h|h|help)        usage && exit 1;;
  lsf|list-files)   list_files ;;
  rmf|rm-file)      remove_files "$@" ;;
  cc|cache-clear)   clear_cache 2>/dev/null ;;
  ch|cached)        get_key_cached >/dev/null ;;
  rmc|rm-cache)     delete_cache 0 >/dev/null ;;
  c|create)         create_file ;;
  t|tree)           sanitize_paths "$@" && _tree "$@" ;;
  s|set)            sanitize_paths "$1" && _set "$@" && cond_copy "$1" ;;
  f|file)           sanitize_paths "$1" && fileset "$@" && cond_copy "$1";;
  a|add)            sanitize_paths "$@" && add "$@" && shift $(($#-1)) && cond_copy "$1";;
  n|new)            sanitize_paths "$@" && new "$@" && shift $(($#-1)) && cond_copy "$1";;
  g|get)            sanitize_paths "$@" && get "$@"    ;;
  x|copy)           sanitize_paths "$1" && copy "$1"   ;;
  l|ls|list)        sanitize_paths "$@" && __NOPACK=y archive_exec ls -Ap1 -- "$@"   ;;
  r|rm)             sanitize_paths "$@" && archive_exec rm -rf -- "$@"                ;;
  m|mv)             sanitize_paths "$@" && move "$@"              ;;
  e|exec)           archive_exec "$@" ;;
  *)                [ -n "$ZPASS_UNK_OP_CALL" ] && "$0" $ZPASS_UNK_OP_CALL "$arg" "$@" ;;
esac
