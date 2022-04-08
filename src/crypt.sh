#!/bin/sh

# $1 = key
encrypt() {
  gzip | openssl enc -aes-256-cbc -pbkdf2 -salt -in - -out - -k "$1"
}

# $1 = key , $2 = keyfile to write
decrypt_with_key()
{
  # evil pipeline return status hack
  { { { {
    openssl enc -d -aes-256-cbc -pbkdf2 -in - -out - -k "$1"; echo $? >&3
  } | gzip -d >&4; } 3>&1; } | { read xs; [ $xs -eq 0 ]; } } 4>&1 || {
    echo "Decrypt failed" >&2
    return 1
  }
  [ -n "$2" ] && echo "$1" > "$2"
  return 0
}

# $1 = keyfile to write
decrypt()
{
  # get remote file
  local base64file
  if [ -n "$remote_host" ] ; then
    base64file=$(remote download "$datapath/$ZPASS_FILE$ZPASS_EXTENSION" | base64) || return $?
  else
    base64file=$(base64 "$file" 2>/dev/null) || { echo "File doesn't exist. Use 'zpass create' to create the file" >&2 && return 1; } # no file
  fi

  if [ -n "$ZPASS_KEY" ]
  then # key given already
    base64 -d <<< "$base64file" | decrypt_with_key "$ZPASS_KEY" "$1" ; ret=$?
  else # prompt for key
    # attempt decrypt from cache
    key=$(get_key_cached) && base64 -d <<< "$base64file" | decrypt_with_key "$key" "$1"
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
        base64 -d <<< "$base64file" | decrypt_with_key "$key" "$1" ; ret=$?
        [ $ret -eq 0 ] && { write_cache "$key" & };
      done
    fi
  fi

  [ $ret -ne 0 ] && { echo "Could not decrypt '$file'" >&2 ; }
  return $ret
}
