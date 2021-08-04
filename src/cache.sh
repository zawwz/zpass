#!/bin/sh

## Cache functions

clear_cache() {
  rm "$cachepath"/*
}

write_cache() {
  echo "$1" > "$cachepath/$(keyfile)"
  delete_cache "$ZPASS_KEY_CACHE_TIME"
}

get_key_cached() {
  cat "$cachepath/$(keyfile)" 2>/dev/null
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
