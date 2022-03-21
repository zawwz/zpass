#!/bin/sh

## Cache functions
get_filecache() {
  echo "$cachepath/$(filehash)$ZPASS_EXTENSION"
}

clear_cache() {
  rm -f "$cachepath"/*
  if [ -S "$sockpath" ] ; then
    agent_cli clear
  fi
}

write_cache() {
  if [ -S "$sockpath" ] ; then
    agent_cli set "$(keyfile)" "$1" "$ZPASS_KEY_CACHE_TIME" >/dev/null
  else
    echo "$1" > "$cachepath/$(keyfile)"
    delete_cache "$ZPASS_KEY_CACHE_TIME"
  fi
}

get_key_cached() {
  if [ -S "$sockpath" ] ; then
    out=$(agent_cli get "$(keyfile)")
    if [ "$out" != "" ] ; then
      echo "$out"
      return 0
    else
      return 1
    fi
  else
    cat "$cachepath/$(keyfile)" 2>/dev/null
  fi
}

# $1 = delay in sec
delete_cache() {
  if [ "$1" -gt 0 ] 2>/dev/null
  then
    nohup sh -c "sleep $1;rm -f '$cachepath/$(keyfile)'" >/dev/null 2>&1 &
  else
    rm -f "$cachepath/$(keyfile)" 2>/dev/null
  fi
}

clean_cache() {
  # key cache
  find "$cachepath" -type f ! -newermt @$(date -d "-$ZPASS_KEY_CACHE_TIME seconds" +%s) -print0 | xargs -0 rm -f
  # tmp folders older than 5 min
  find "$TMPDIR" -maxdepth 1 -type d -name 'zpass_*' ! -mmin 5 -print0 | xargs -0 rm -f
}
