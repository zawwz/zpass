#!/bin/sh

# $1 = tmpdir , $2 = keyfile
unpack() {
  rm -rf "$1" || return $?
  mkdir -p "$1" || return $?
  (
    set -e
    cd "$1"
    decrypt "$2" | tar -xf - 2>/dev/null
  )
}

# $1 = tmpdir , $2 = keyfile
pack()
{
  # clean empty dirs
  archive="archive_$(randalnum 5)"
  (
    cd "$1" || exit $?
    if [ -n "$2" ]
    then
      key=$(cat "$2") && rm "$2" || exit $?
    else
      key=$(new_key_with_confirm) || exit $?
    fi
    tar -cf - -- * | encrypt "$key" > "$1/$archive" || exit $?
  ) || return $?
  if [ -n "$ZPASS_REMOTE_ADDR" ]
  then
    [ -z "$ZPASS_PATH" ] && datapath="~/.local/share/zpass"
    if [ -n "$ZPASS_SSH_ID" ]
    then scp -i "$ZPASS_SSH_ID" "$1/$archive" "$ZPASS_REMOTE_ADDR:$datapath/$ZPASS_FILE$ZPASS_EXTENSION" >/dev/null || return $?
    else scp "$1/$archive" "$ZPASS_REMOTE_ADDR:$datapath/$ZPASS_FILE$ZPASS_EXTENSION" >/dev/null || return $?
    fi
    rm -f "$1/$archive" 2>/dev/null
    return 0
  else
    mv -f "$1/$archive" "$file"
  fi
}

# $@ = command to execute inside archive
# set env __NOPACK to not repack after command
archive_exec()
{
  err=0
  # tmp files
  tmpdir="$TMPDIR/zpass_$(randalnum 5)"
  keyfile="$tmpdir/$(randalnum 5).key"
  # operation
  (
    # unpack
    unpack "$tmpdir/archive" "$keyfile" || exit $?
    # execute
    (cd "$tmpdir/archive" && "$@") || exit $?
    # repack
    [ -z "$__NOPACK" ] && { pack "$tmpdir/archive" "$keyfile" || exit $?; }
    exit 0
  ) || err=$?
  # cleanup
  rm -rf "$tmpdir"
  return $err
}

# no argument
create() {
  if [ -f "$file" ]
  then
    tmpdir="$TMPDIR/zpass_$(randalnum 5)"
    # pack n repack with no tmp key: create new
    unpack "$tmpdir" || return $?
    pack "$tmpdir" || { echo "Encryption error" >&2 && return 1 ; }
    rm -rf "$tmpdir"
  else
    # if remote: file tmp
    [ -n "$ZPASS_REMOTE_ADDR" ] && {
      file="$TMPDIR/zpass_$(filehash)$ZPASS_EXTENSION"
    }
    # get key
    [ -z "$ZPASS_KEY" ] && {
      ZPASS_KEY=$(new_key_with_confirm) || { echo "Cancelled" >&2 && return 100 ; }
    }
    # create archive
    tar -cf - -T /dev/null | encrypt "$ZPASS_KEY" > "$file" || {
      echo "Encryption error" >&2
      # echo "$tmperr" >&2
      rm "$file"
      return 1
    }
    [ -n "$ZPASS_REMOTE_ADDR" ] && {
      ssh "$ZPASS_REMOTE_ADDR" "mkdir -p '$datapath'"
      if [ -n "$ZPASS_SSH_ID" ]
      then scp -i "$ZPASS_SSH_ID" "$file" "$ZPASS_REMOTE_ADDR:$datapath/$ZPASS_FILE$ZPASS_EXTENSION" >/dev/null || return $?
      else scp "$file" "$ZPASS_REMOTE_ADDR:$datapath/$ZPASS_FILE$ZPASS_EXTENSION" >/dev/null || return $?
      fi
      rm -rf "$file" 2>/dev/null
    }
  fi
  return 0
}
