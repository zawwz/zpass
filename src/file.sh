#!/bin/sh

list_files() {
  if [ -n "$ZPASS_REMOTE_ADDR" ] ; then
    echo "$cmd" | sftp_cmd -b- << EOF
cd "$datapath"
ls -1
EOF
  else
    (
      cd "$datapath"
      ls -1
    )
  fi | grep "$(escape_chars "$ZPASS_EXTENSION")$"
}

remove_files()
{
  if [ -n "$ZPASS_REMOTE_ADDR" ] ; then
    echo "$cmd" | sftp_cmd -b- << EOF
rm "$datapath/$N$ZPASS_EXTENSION"
EOF
  else
      rm "$datapath/$N$ZPASS_EXTENSION"
  fi
}
