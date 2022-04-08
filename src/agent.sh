
sockpath() {
  echo "${1-$sockpath}"
}

start_agent() {
  redis-server --save "" --port 0 --unixsocket "$(sockpath)" --unixsocketperm 700
}

# $1 = socket
redis_cli() {
  redis-cli --raw -s "$1"
}

escape() {
  printf "%s\n" "$1" | sed 's/\"/\\\"/g'
}

agent_cli() {
  socket=$(sockpath)
  op=$1
  shift
  case "$op" in
    set)
      echo "set $1 \"$(escape "$2")\""
      echo "expire $1 $3"
      ;;
    expire) echo "expire $1 $2" ;;
    get) echo "get $1" ;;
    clear) echo "FLUSHDB" ;;
  esac | redis_cli "$(sockpath)"
}
