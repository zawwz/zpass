# $1 = cond value , $2 = precede , $3 = separator
cond_gen() {
  [ -n "$1" ] && env printf "%q%s%q" "$2" "$3" "$1"
}

# $@ = command
ftps_cmd() {
  shift 3
  user=${ZPASS_REMOTE_ADDR%%@*}
  host=${ZPASS_REMOTE_ADDR#*@}
  lftp << EOF
set ftp:ssl-allow true ; set ssl:verify-certificate no ; set ftp:ssl-auth TLS
open ftp://$host$(cond_gen "$ZPASS_REMOTE_PORT" ":")
user $user $ZPASS_REMOTE_PASSWORD
$(cat)
EOF
}

# $@ = args
sftp_cmd() {
  { sftp -b- $(cond_gen "$ZPASS_REMOTE_PORT" -P " ") $(cond_gen "$ZPASS_SSH_ID" -i " ") "$@" "$ZPASS_REMOTE_ADDR" || return $?; } | grep -v "^sftp>" || true
}

# $@ args
scp_cmd() {
  scp $(cond_gen "$ZPASS_REMOTE_PORT" -P " ")  $(cond_gen "$ZPASS_SSH_ID" -i " ") "$@"
}

# $@ = args
ssh_cmd() {
  ssh $(cond_gen "$ZPASS_REMOTE_PORT" -p " ")  $(cond_gen "$ZPASS_SSH_ID" -i " ") "$@"
}

# $1 = protocol , $2 = local file , $3 = remote file
upload() {
  case $1 in
    scp) scp_cmd "$2" "$ZPASS_REMOTE_ADDR:$3" ;;
    sftp|ftps) "$1"_cmd >/dev/null << EOF
put "$2" "$3"
EOF
  esac
}

# $1 = protocol, $2 = remote file , $3 = local file
download() {
  case $1 in
    scp) scp_cmd "$ZPASS_REMOTE_ADDR:$2" "$3" ;;
    sftp|ftps) ${1}_cmd >/dev/null << EOF
get "$2" "$3"
EOF
  esac
}

# $1 = protocol
list() {
  case $1 in
    scp) ssh_cmd "cd '$datapath' && ls -1" ;;
    sftp|ftps) ${1}_cmd >/dev/null << EOF
cd "$datapath"
ls -1
EOF
  esac
}

# $1 = protocol , $2 = file
delete() {
  case $1 in
    scp) ssh_cmd "rm '$2'" ;;
    sftp|ftps) ${1}_cmd >/dev/null << EOF
rm "$2"
EOF
  esac
}

# $1 = action , $@ = arguments
remote() {
  action=$1
  shift 1
  case "${ZPASS_REMOTE_METHOD-scp}" in
    scp|sftp|ftps) $action "${ZPASS_REMOTE_METHOD-scp}" "$@" ;;
    *) echo "Unknown remote method: $ZPASS_REMOTE_METHOD" ;;
  esac
}
