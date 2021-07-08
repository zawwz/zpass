#!/bin/sh

list_files() {
  if [ -n "$ZPASS_REMOTE_ADDR" ] ; then
    remote list
  else
    ( cd "$datapath" && ls -1 )
  fi | grep "$(escape_chars "$ZPASS_EXTENSION")$"
}

remove_files()
{
  for file
  do
    if [ -n "$ZPASS_REMOTE_ADDR" ] ; then
      remote delete "$datapath/$file$ZPASS_EXTENSION"
    else
      rm "$datapath/$file$ZPASS_EXTENSION"
    fi
  done
}
