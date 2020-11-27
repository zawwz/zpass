#!/bin/sh

clipboard()
{
  unset in
  read -r in
  while read -r ln
  do
    in="$in
$ln"
  done
  printf "%s" "$in" | xclip -selection clipboard
  which wl-copy >/dev/null 2>&1 && printf "%s" "$in" | wl-copy
}

# $1 = delay in sec
clipboard_clear() {
  if [ -n "$1" ]
  then
    for I in $(screen -ls | grep "$fname"_clipboard | awk '{print $1}')
    do
      screen -S "$I" -X stuff "^C"
    done
    screen -dmS "$fname"_clipboard sh -c "sleep $1
      xclip -selection clipboard < /dev/null
      which wl-copy 2>&1 && wl-copy < /dev/null
      sleep 1"
  else
    echo | clipboard
  fi
}

copy_check()
{
  if ps -e | grep -qi wayland
  then
    which wl-copy >/dev/null 2>&1 || error 1 "ERROR: running wayland but wl-clipboard is not installed"
  elif [ -n "$DISPLAY" ]
  then
    which xclip >/dev/null 2>&1 || error 1 "ERROR: running X but xclip is not installed"
  else
    error 1 "ERROR: no graphical server detected"
  fi
  return 0
}
