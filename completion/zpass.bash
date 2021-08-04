#/usr/bin/env bash

# $1 = input arg , $@ = completions
_completion_check_expands() {
  local arg=$1
  shift 1
  local matching=()
  local N=0
  for I ; do
    [ "$I" != "${I#"$arg"}" ] && matching[N++]=$I
  done
  local superset=${matching[0]:0:${#arg}}
  [ "${superset#"$arg"}" = "$superset" ] && return 1
  for N in "${matching[@]}" ; do
    [ "${N#"$superset"}" = "$N" ] && return 1
  done
  return 0
}

_zpass_completion()
{
  local _cw1="list-files cache-clear help rm-file ls tree create get copy set file add new rm mv exec cached rm-cache"
  local _cw1_val_all="l ls g get a add n new r rm m mv"
  local _cw1_val1="s set f file x copy"
  local _cw1_files="rmf rm-file"
  local N=0
  local _compwords=
  local WORDS=()
  local cur=$2
  COMPREPLY=()

  if  { [ "$COMP_CWORD" -eq "2" ] && echo "$_cw1_val1" | grep -qw -- "${COMP_WORDS[1]}" ; } ||
      { [ "$COMP_CWORD" -gt "1" ] && echo "$_cw1_val_all" | grep -qw -- "${COMP_WORDS[1]}"; } ; then

    zpass cached || return 0

    local dir=$2
    [ "${dir}" = "${dir%/}" ] && dir=$(dirname "$2")

    N=0
    for j in $(zpass ls "$dir") ; do
     [ "$j" = "${j%/}" ] && j="$j "
     WORDS[N++]=$j
    done
    cur=$(basename "$cur")
    [ "$2" != "${2%/}" ] && cur=""

    if _completion_check_expands "$cur" "${WORDS[@]}" ; then
      N=0
      if [ -n "$cur" ] ; then
      	for I in "${WORDS[@]}" ; do
      		[ "$I" != "${I#"$cur"}" ] && COMPREPLY[N++]=$I
      	done
      else
        COMPREPLY=("${WORDS[@]}")
      fi
      N=0
      for I in "${COMPREPLY[@]}" ; do
        local tt="$dir/$I"
        COMPREPLY[N++]="${tt#./}"
      done
    else
      if [ -n "$cur" ] ; then
        N=0
      	for I in "${WORDS[@]}" ; do
      		[ "$I" != "${I#"$cur"}" ] && COMPREPLY[N++]=$I
      	done
      else
        COMPREPLY=("${WORDS[@]}")
      fi
    fi

  else

  	if [ "$COMP_CWORD" = "1" ] ; then
  		_compwords="$_cw1"
  	elif [ "$COMP_CWORD" -gt "1" ] && echo " $_cw1_files " | grep -qF -- " ${COMP_WORDS[1]} " ; then
  		_compwords=$(zpass lsf)
  	fi
  	for I in $_compwords ; do
  		WORDS[N++]="$I "
  	done

    N=0
    if [ -n "$cur" ] ; then
      for I in "${WORDS[@]}" ; do
        [ "$I" != "${I#"$cur"}" ] && COMPREPLY[N++]=$I
      done
    else
      COMPREPLY=("${WORDS[@]}")
    fi

  fi
}

complete -o nospace -F _zpass_completion -o dirnames zpass
