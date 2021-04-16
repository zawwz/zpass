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
  if [ "$XDG_SESSION_TYPE" = x11 ] ; then
    printf "%s" "$in" | xclip -selection clipboard
  elif [ "$XDG_SESSION_TYPE" = wayland ] ; then
    printf "%s" "$in" | wl-copy
  fi
}

get_clipboard() {
  if [ "$XDG_SESSION_TYPE" = x11 ] ; then
    xclip -selection clipboard -o
  elif [ "$XDG_SESSION_TYPE" = wayland ] ; then
    wl-paste
  fi
}

# $1 = delay in sec
clipboard_clear() {
  if [ -n "$1" ]
  then
    clipval=$(get_clipboard | sed 's|"|\"|g;s|\\|\\|g;' )
    tmpfifo="$TMPDIR/zpass_tmpfifo_$(randalnum 20)"
    mkfifo "$tmpfifo"
    nohup sh -c '#LXSH_PARSE_MINIFY
      pass=$(cat "$2")
      rm -f "$2"
      sleep $1
      clip=$(
        if [ "$XDG_SESSION_TYPE" = x11 ] ; then
          xclip -selection clipboard -o 2>/dev/null
        elif [ "$XDG_SESSION_TYPE" = wayland ] ; then
          wl-paste
        fi
      )
      [ "$clip" != "$pass" ] && exit 1

      if [ "$XDG_SESSION_TYPE" = x11 ] ; then
        xclip -selection clipboard < /dev/null
      elif [ "$XDG_SESSION_TYPE" = wayland ] ; then
        wl-copy < /dev/null
      fi
    ' zpass_clipclear "$1" "$tmpfifo" >/dev/null 2>&1 &
    get_clipboard > "$tmpfifo"
  else
    echo | clipboard
  fi
}

copy_check()
{
  if [ "$XDG_SESSION_TYPE" = wayland ]
  then
    which wl-copy >/dev/null 2>&1 || error 1 "ERROR: running wayland but wl-clipboard is not installed"
  elif [ "$XDG_SESSION_TYPE" = x11 ]
  then
    which xclip >/dev/null 2>&1 || error 1 "ERROR: running X but xclip is not installed"
  else
    error 1 "ERROR: no graphical server detected"
  fi

  return 0
}
