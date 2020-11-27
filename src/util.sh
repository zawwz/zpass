#!/bin/sh

error(){
  ret=$1 && shift 1 && echo "$*" >&2 && exit $ret
}

randalnum() {
  tr -cd '[a-zA-Z]' < /dev/urandom | head -c $1
}

# $* = input
escape_chars() {
  echo "$*" | sed 's|\.|\\\.|g;s|/|\\/|g'
}

remove_trailing_newline() {
  awk 'NR>1{print PREV} {PREV=$0} END{printf("%s",$0)}'
}

# $@ = paths
sanitize_paths()
{
  for N
  do
    echo "$N" | grep -q "^/" && echo "Path cannot start with /" >&2 && return 1
    echo "$N" | grep -qw ".." && echo "Path cannot contain .." >&2 && return 1
  done
  return 0
}

# $1 = file
getpath() {
  if [ -n "$ZPASS_REMOTE_ADDR" ]
  then
    echo "$ZPASS_REMOTE_PORT:$ZPASS_REMOTE_ADDR:$file"
  else
    echo "$(pwd)/$file"
  fi
}

# $1 = file
filehash(){
  getpath "$file" | md5sum | cut -d' ' -f1
}

keyfile(){
  printf "%s.key" "$(filehash)"
}

_cmd_() {
  if [ -n "$ZPASS_REMOTE_ADDR" ]
  then
    if [ -n "$ZPASS_SSH_ID" ]
    then
      ssh -i "$ZPASS_SSH_ID" "$ZPASS_REMOTE_ADDR" "$@" || return $?
    else
      ssh "$ZPASS_REMOTE_ADDR" "$@" || return $?
    fi
  else
    sh -c "$*"
  fi
}
