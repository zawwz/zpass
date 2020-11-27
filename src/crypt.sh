#!/bin/sh

# $1 = key
encrypt() {
  gpg --pinentry-mode loopback --batch --passphrase "$1" -o - -c -
}

# $1 = key , $2 = keyfile to write
decrypt_with_key()
{
  gpg --pinentry-mode loopback --batch --passphrase "$1" -o - -d "$file" 2>/dev/null && ret=$? && [ -n "$2" ] && echo "$1" > "$2"
  return $ret
}

# $1 = keyfile to write
decrypt()
{
  # get remote file
  [ -n "$ZPASS_REMOTE_ADDR" ] && {
    file="$TMPDIR/zpass_$(filehash)$ZPASS_EXTENSION"
    [ -z "$ZPASS_PATH" ] && datapath="~/.local/share/zpass"
    if [ -n "$ZPASS_SSH_ID" ]
    then scp -i "$ZPASS_SSH_ID" "$ZPASS_REMOTE_ADDR:$datapath/$ZPASS_FILE$ZPASS_EXTENSION" "$file" >/dev/null || return $?
    else scp "$ZPASS_REMOTE_ADDR:$datapath/$ZPASS_FILE$ZPASS_EXTENSION" "$file" >/dev/null || return $?
    fi
  }
  cat "$file" >/dev/null 2>&1 || { echo "File doesn't exist. Use 'zpass create' to create the file" >&2 && return 1; } # no file

  if [ -n "$ZPASS_KEY" ]
  then # key given already
    decrypt_with_key "$ZPASS_KEY" "$1" ; ret=$?
  else # prompt for key
    # attempt decrypt from cache
    key=$(get_key_cached) && decrypt_with_key "$key" "$1"
    ret=$?
    if [ $ret -ne 0 ]
    then
      # cache was incorrect: delete
      delete_cache >/dev/null 2>&1
      # try loop
      tries=0
      while [ $ret -ne 0 ] && [ $tries -lt 3 ]
      do
        key=$(ask_key) || { echo "Cancelled" >&2 && return 100 ; }
        tries=$((tries+1))
        decrypt_with_key "$key" "$1" ; ret=$?
      done
    fi
  fi

  # remove temporary file
  [ -n "$ZPASS_REMOTE_ADDR" ] && rm -rf "$file" 2>/dev/null

  [ $ret -ne 0 ] && { echo "Could not decrypt '$file'" >&2 ; }
  return $ret
}
