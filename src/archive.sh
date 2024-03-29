#!/bin/sh

# $1 = tmpdir , $2 = keyfile
unpack() {
  rm -rf "$1" || return $?
  mkdir -p "$1" || return $?
  (
    set -e
    cd "$1"
    decrypt "$2" | tar -xf -
  )
}

# $1 = tmpdir , $2 = keyfile
pack()
{
  # clean empty dirs
  archive="archive_$(randalnum 20)"
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
  if [ -n "$remote_host" ]
  then
    ret=0
    remote upload "$1/$archive" "$datapath/$ZPASS_FILE$ZPASS_EXTENSION" || ret=$?
    rm -f "$1/$archive" 2>/dev/null
    return $ret
  else
    mv -f "$1/$archive" "$FILE"
  fi
}

# $@ = command to execute inside archive
# set env __NOPACK to not repack after command
archive_exec()
{
  err=0
  # tmp files
  archive_tmpdir="$(tmprand)"
  keyfile="$archive_tmpdir/$(randalnum 20).key"
  mkdir -p "$archive_tmpdir" || exit $?
  chmod 700 "$archive_tmpdir" || exit $?
  # operation
  (
    # unpack
    unpack "$archive_tmpdir/archive" "$keyfile" || exit $?
    # execute
    (cd "$archive_tmpdir/archive" && "$@") || exit $?
    # repack
    [ -z "$__NOPACK" ] && { pack "$archive_tmpdir/archive" "$keyfile" || exit $?; }
    exit 0
  ) || err=$?
  # cleanup
  rm -rf "$archive_tmpdir"
  return $err
}

# no argument
create_file() {
  if [ -n "$remote_host" ] ; then
    file="$TMPDIR/zpass_$(filehash)$ZPASS_EXTENSION"
    if base64contents=$(remote download "$datapath/$ZPASS_FILE$ZPASS_EXTENSION" 2>&1) ; then

      # unpack locally
      remote_host= unpack "$archive_tmpdir" || {
        rm -rf "$archive_tmpdir" "$file"
        return 1
      }
      # pack and send
      pack "$archive_tmpdir" || {
        echo "Encryption error" >&2
        rm -rf "$archive_tmpdir" "$file"
        return 1
      }
      # cleanup
      rm -rf "$archive_tmpdir" "$file"
    else
      # get key
      [ -z "$ZPASS_KEY" ] && {
        ZPASS_KEY=$(new_key_with_confirm) || { echo "Cancelled" >&2 && return 100 ; }
      }
      # create archive
      tar -cf - -T /dev/null | encrypt "$ZPASS_KEY" > "$file" || {
        echo "Encryption error" >&2
        rm -f "$file"
        return 1
      }

      ret=0
      remote create "$file" "$datapath/$ZPASS_FILE$ZPASS_EXTENSION" || ret=$?
      rm -f "$file"
      return $ret
    fi

  elif [ -f "$file" ] ; then
    archive_tmpdir="$TMPDIR/zpass_$(randalnum 20)"
    # pack n repack with no tmp key: create new
    unpack "$archive_tmpdir" || return $?
    pack "$archive_tmpdir" || { echo "Encryption error" >&2 && return 1 ; }
    rm -rf "$archive_tmpdir"
  else
    # get key
    [ -z "$ZPASS_KEY" ] && {
      ZPASS_KEY=$(new_key_with_confirm) || { echo "Cancelled" >&2 && return 100 ; }
    }
    # create archive
    tar -cf - -T /dev/null | encrypt "$ZPASS_KEY" > "$file" || {
      echo "Encryption error" >&2
      rm "$file"
      return 1
    }
  fi
  return 0
}
