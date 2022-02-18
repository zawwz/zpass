# $1 = cond value , $2 = precede , $3 = separator
cond_gen() {
  [ -n "$1" ] && env printf "%q%s%q" "$2" "$3" "$1"
}

# $@ = command
ftps_cmd() {
  shift 3
  lftp << EOF
set ftp:ssl-allow true ; set ssl:verify-certificate no ; set ftp:ssl-auth TLS
open ftp://$remote_host$(cond_gen "$ZPASS_REMOTE_PORT" ":")
user $remote_user $ZPASS_REMOTE_PASSWORD
$(cat)
EOF
}

# $@ = args
sftp_cmd() {
  { sftp -oStrictHostKeyChecking=no -b- $(cond_gen "$ZPASS_REMOTE_PORT" -P " ") $(cond_gen "$ZPASS_SSH_ID" -i " ") "$@" "${remote_user+${remote_user}@}$remote_host" || return $?; } | grep -v "^sftp>" || true
}

# $@ args
scp_cmd() {
  scp -oStrictHostKeyChecking=no -q $(cond_gen "$ZPASS_REMOTE_PORT" -P " ")  $(cond_gen "$ZPASS_SSH_ID" -i " ") "$@"
}

# $@ = args
ssh_cmd() {
  ssh $(cond_gen "$ZPASS_REMOTE_PORT" -p " ")  $(cond_gen "$ZPASS_SSH_ID" -i " ") "$@"
}

# $1 = protocol , $2 = local file , $3 = remote file
upload() {
  case $1 in
    scp) scp_cmd "$2" "${remote_user+${remote_user}@}$remote_host:$3" ;;
    webdav) webdav_cmd "$3" -T "$2" ;;
    sftp|ftps) "$1"_cmd >/dev/null << EOF
put "$2" "$3"
EOF
  esac
  [ $? -eq 0 ] || {
    echo "ERROR: failed to upload" >&2
    return 1
  }
  cp "$2" "$(get_filecache)"
}

# $1 = protocol, $2 = remote file , $3 = local file
download() {
  if [ "$_ZPASS_USE_CACHE" = true ] && [ -f "$(get_filecache)" ] ; then
    cp "$(get_filecache)" "$3"
    return $?
  fi

  case $1 in
    scp) scp_cmd "${remote_user+${remote_user}@}$remote_host:$2" "$3" ;;
    webdav) webdav_cmd "$2" > "$3" ;;
    sftp|ftps) ${1}_cmd >/dev/null << EOF
get "$2" "$3"
EOF
;;
  esac
  if [ $? -eq 0 ] ; then
    # could download no problem
    cached_file=$(get_filecache)
    # copy only if different
    diff "$3" "$cached_file" >/dev/null 2>&1 || cp "$3" "$cached_file"
    return 0
  else
    # could not download: try cache
    [ -f "$3" ] || return $?
    echo "WARN: failed to download archive, using cache" >&2
    cp "$(get_filecache)" "$3"
  fi
}

# $1 = protocol
list() {
  case $1 in
    scp) ssh_cmd "cd '$datapath' && ls -1" ;;
    webdav) webdav_list ;;
    sftp|ftps) ${1}_cmd << EOF
cd "$datapath"
ls -1
EOF
  esac
}

# $1 = protocol , $2 = file
delete() {
  case $1 in
    scp) ssh_cmd "rm '$2'" ;;
    webdav) webdav_delete "$2" ;;
    sftp|ftps) ${1}_cmd >/dev/null << EOF
rm "$2"
EOF
  esac
}

# $1 = protocol , $2 = local file , $3 = remote file
create() {
  case $1 in
    scp) ssh_cmd "mkdir -p '$(dirname "$3")' && cat > '$3'" < "$2" ;;
    webdav) webdav_create "$2" "$3" ;;
    sftp|ftps) ${1}_cmd >/dev/null << EOF
mkdir "$datapath"
put "$2" "$3"
EOF
  esac
}

# $1 = action , $@ = arguments
remote() {
  action=$1
  shift 1
  case "${ZPASS_REMOTE_METHOD-scp}" in
    scp|sftp|ftps|webdav) $action "${ZPASS_REMOTE_METHOD-scp}" "$@" ;;
    *) echo "Unknown remote method: $ZPASS_REMOTE_METHOD" >&2 ;;
  esac
}
