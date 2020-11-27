#!/bin/lxsh

%include util.sh config.sh *.sh

## pre exec

clean_cache 2>/dev/null
[ $# -lt 1 ] && usage && return 1

arg=$1
shift 1

## exec

case $arg in
  -h|h|help)        usage && exit 1;;
  lsf|list-files)   list_files ;;
  rmf|rm-file)      remove_files "$@" ;;
  cc|cache-clear)   clear_cache 2>/dev/null ;;
  ch|cached)        get_key_cached >/dev/null 2>&1 ;;
  rmc|rm-cache)     delete_cache 0 >/dev/null 2>&1 ;;
  c|create)         create      ;;
  t|tree)           _tree "$@"  ;;
  s|set)            _set "$@"   ;;
  a|add)            add "$@"    ;;
  n|new)            new "$@"    ;;
  g|get)            get "$@"    ;;
  x|copy)           copy "$1"   ;;
  e|exec)           archive_exec "$@" ;;
  l|ls|list)        sanitize_paths "$@" && __NOPACK=y archive_exec ls -Apw1 -- "$@"   ;;
  r|rm)             sanitize_paths "$@" && archive_exec rm -rf -- "$@"                ;;
  m|mv)             sanitize_paths "$@" && archive_exec mv -f -- "$@"              ;;
  *)                [ -n "$ZPASS_UNK_OP_CALL" ] && "$0" $ZPASS_UNK_OP_CALL "$arg" "$@" ;;
esac
