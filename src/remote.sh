# $@ = args
sftp_cmd() {
  [ -n "$ZPASS_REMOTE_ADDR" ] || return $?
  if [ -n "$ZPASS_SSH_ID" ] ; then
    sftp -i "$ZPASS_SSH_ID" "$@" "$ZPASS_REMOTE_ADDR"
  else
    sftp "$@" "$ZPASS_REMOTE_ADDR"
  fi | grep -v "^sftp>"
  return 0
}

# $1 = local file , $2 = remote file
sftp_upload() {
  sftp_cmd -b- >/dev/null << E
put "$1" "$2"
E
}

# $1 = remote file , $2 = local file
sftp_download() {
  sftp_cmd -b- >/dev/null << E
get "$1" "$2"
E
}
