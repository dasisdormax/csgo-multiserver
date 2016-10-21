#! /bin/bash

# (C) 2016 Maximilian Wende <maximilian.wende@gmail.com>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0




#######################
#                     #
#  TODO: Add logging  #
#                     #
#######################




if [[ $DEBUG ]]; then exec 3>&1; else exec 3>/dev/null; fi

caterr  () { printf "\x1b[31m" 1>&2; cat 1>&2; printf "\x1b[m" 1>&2; }

catwarn () { printf "\x1b[33m" 1>&2; cat 1>&2; printf "\x1b[m" 1>&2; }

catinfo () { printf "\x1b[36m"     ; cat     ; printf "\x1b[m"     ; }

# TODO: logging and loglevels
log () { false; }

indent () { sed 's/^/    /'; }

trace () {
	local i=1
	while [[ ${FUNCNAME[$i]} != main ]] && (( i < ${#FUNCNAME[@]} )); do
		local func=${FUNCNAME[$i+1]}
		local line=${BASH_LINENO[$i]}
		case $func in
			( command_not_found_handle ) ;;
			( * )
				if (( i > 1 )); then printf "\n          "; fi
				printf "in %-40s (line %3s)" $func $line ;;
			esac
		(( i++ )); done
}

fatal () {
	{
		printf "\x1b[1;35mFatal: \x1b[22m   "; trace; echo
		fmt -w67 | indent
		printf "\x1b[m"
	} >&2
	false
}

error () {
	{
		printf "\x1b[1;31mError:\x1b[22m    "; trace; echo
		fmt -w67 | indent
		printf "\x1b[m"
	} >&2
	false
}

warning () {
	printf "\x1b[1;33mWarning:\x1b[22m  "; trace >&3; echo
	fmt -w67 | indent
	printf "\x1b[m"
}

info () {
	printf "\x1b[1;36mInfo:\x1b[22m     "; trace >&3; echo
	fmt -w67 | indent
	printf "\x1b[m"
}

success () {
	printf "\x1b[1;32mSuccess:\x1b[22m  "; trace >&3; echo
	fmt -w67 | indent
	printf "\x1b[m"
}

debug () {
	{
		printf "\x1b[1;34mDebug:\x1b[22m    "; trace; echo
		fmt -w67 | indent
		printf "\x1b[m"
	} >&3
}

# Make text $1 bold
bold () { printf "\x1b[1m%s\x1b[22m" "$1"; }