#!/bin/sh

list_files() {
  _cmd_ "cd '$datapath' 2>/dev/null && find . -maxdepth 1 -type f -regex '.*$ZPASS_EXTENSION\$'" | sed "s/$(escape_chars "$ZPASS_EXTENSION")\$//g; s|.*/||g"
}

remove_files()
{
  for N
  do
    _cmd_ "rm '$datapath/$N$ZPASS_EXTENSION'" || exit $?
  done
}
