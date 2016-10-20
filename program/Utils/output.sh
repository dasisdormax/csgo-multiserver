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
# TODO: Auto-format using 'fmt -c'




caterr  () { printf "\x1b[31m" 1>&2; cat 1>&2; printf "\x1b[m" 1>&2; }

catwarn () { printf "\x1b[33m" 1>&2; cat 1>&2; printf "\x1b[m" 1>&2; }

catinfo () { printf "\x1b[36m"     ; cat     ; printf "\x1b[m"     ; }

# TODO: logging and loglevels
log () { false; }

indent () { sed 's/^/    /'; }

trace () {
	local i=1;
	local indent
	while [[ ${FUNCNAME[$i]} != main ]]; do
		printf "%s( from %s at %s:%s )\n" "$indent" \
			${FUNCNAME[$i+1]} ${BASH_SOURCE[$i+1]/"$THIS_DIR/"/} ${BASH_LINENO[$i]}
		indent="         "
		(( i++ ))
	done
}

error () {
	printf "\x1b[1;31mError:\x1b[22m   " >&2
	trace >&2
	fmt -w67 | indent >&2
	printf "\x1b[m" >&2
	false
}

warning () {
	printf "\x1b[1;33mWarning:\x1b[22m " >&2
	trace >&2
	fmt -w67 | indent >&2
	printf "\x1b[m" >&2
}

info () {
	printf "\x1b[1;36mInfo:\x1b[22m\n"
	fmt -w67 | indent >&2
	printf "\x1b[m" >&2
}

# Make text $1 bold
bold () { printf "\x1b[1m%s\x1b[22m" "$1"; }