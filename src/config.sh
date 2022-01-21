#!/bin/sh

# XDG config/cache
datapath=".local/share/zpass"
cachepath="$HOME/.cache/zpass"
configpath="$HOME/.config/zpass"
[ -n "$XDG_CONFIG_HOME" ] && configpath="$XDG_CONFIG_HOME/zpass"
[ -n "$XDG_CACHE_HOME" ] && cachepath="$XDG_CACHE_HOME/zpass"
CONFIGFILE=${CONFIGFILE-$configpath/default.conf}

[ -z "$TMPDIR" ] && TMPDIR=/tmp

# stash env config
tmpenv="$TMPDIR/zpassenv_$(randalnum 20)"
env | grep '^ZPASS_.*=' | sed "s/'/'\\\''/g;s/=/='/;s/$/'/g" > "$tmpenv"

# load config file
[ -f "$CONFIGFILE" ] && { . "$CONFIGFILE" || exit $? ; }

[ -n "$XDG_DATA_HOME" ] && [ -z "$ZPASS_REMOTE_ADDR" ] && datapath="$XDG_DATA_HOME/zpass"

. "$tmpenv" || exit $?
rm -f "$tmpenv" 2>/dev/null

# resolve zpass_path
datapath=${ZPASS_PATH-$datapath}
cachepath=${ZPASS_CACHE_PATH-$cachepath}

# default ZPASS
ZPASS_FILE=${ZPASS_FILE-default}
ZPASS_EXTENSION=${ZPASS_EXTENSION-.tar.gpg}
ZPASS_KEY_CACHE_TIME=${ZPASS_KEY_CACHE_TIME-60}
ZPASS_CLIPBOARD_TIME=${ZPASS_CLIPBOARD_TIME-30}
ZPASS_UNK_OP_CALL=${ZPASS_UNK_OP_CALL-copy}
ZPASS_RAND_LEN=${ZPASS_RAND_LEN-20}
ZPASS_RAND_SET=${ZPASS_RAND_SET-'a-zA-Z0-9\!-.'}

RES_OPTIONS=${RES_OPTIONS-'retrans:1 retry:1 timeout:1 attempts:1'}
export RES_OPTIONS

# datapath resolution
# remove tildes
datapath="${datapath#\~/}"
[ "$datapath" = '~' ] && datapath=""
# if not remote and not absolute: add HOME
[ -z "$ZPASS_REMOTE_ADDR" ] && [ "$(echo "$datapath" | cut -c1)" != '/' ] && datapath="$HOME/$datapath"

file="$datapath/$ZPASS_FILE$ZPASS_EXTENSION"
FILE=$file

## Resolve remote

remote_user=$ZPASS_REMOTE_USER

# remote addr has @
if [ "${ZPASS_REMOTE_ADDR}" != "${ZPASS_REMOTE_ADDR##*@*}" ] ; then
  remote_user=${ZPASS_REMOTE_ADDR%%@*}
  remote_host=${ZPASS_REMOTE_ADDR#*@}
else
  remote_host=$ZPASS_REMOTE_ADDR
fi

[ -z "$remote_host" ] && { mkdir -p "$datapath" 2>/dev/null || error 1 "Could not create '$datapath'"; }
mkdir -p "$cachepath" 2>/dev/null && chmod -R go-rwx "$cachepath" 2>/dev/null
