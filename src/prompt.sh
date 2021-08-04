#!/bin/sh

# $1 = prompt
console_prompt_hidden()
{
  (
    trap _stop INT
    local prompt
    printf "%s" "$1" >&2
    stty -echo
    read -r prompt || { stty echo; return 1; }
    stty echo
    printf "\n" >&2
    echo "$prompt"
  )
}

# $1 = prompt message
prompt_password() {
  if [ -n "$DISPLAY" ]
  then
    if which kdialog >/dev/null 2>&2
    then kdialog --title "$fname" --password "$1" 2>/dev/null
    else zenity --title "$fname" --password 2>/dev/null
    fi
  else
    console_prompt_hidden "$1: "
  fi
}

# $1 = message
error_dialog() {
  if which kdialog >/dev/null 2>&2
  then kdialog --title "$fname" --error "$1" 2>/dev/null
  else zenity --title "$fname" --error --text="$1" 2>/dev/null
  fi
}

new_key_with_confirm()
{
  [ -n "$ZPASS_KEY" ] && echo "$ZPASS_KEY" && return 0
  pass1=1
  pass2=2
  while [ "$pass1" != "$pass2" ]
  do
    pass1=$(prompt_password "Enter new key") || error 100 "Cancelled"
    pass2=$(prompt_password "Confirm key") || error 100 "Cancelled"
    [ "$pass1" != "$pass2" ] && error_dialog "Passwords do not match.\nTry again"
  done
  write_cache "$pass1" &
  echo "$pass1"
}

# $1 = prompt message
ask_key() {
  message="Enter key"
  [ -n "$1" ] && message="$1"
  key=$(prompt_password "$message") || return $?
  write_cache "$key" &
  echo "$key"
}
