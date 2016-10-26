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





caterr  () { printf "\x1b[31m" 1>&2; cat 1>&2; printf "\x1b[m" 1>&2; }

catwarn () { printf "\x1b[33m" 1>&2; cat 1>&2; printf "\x1b[m" 1>&2; }

catinfo () { printf "\x1b[36m"     ; cat     ; printf "\x1b[m"     ; }




################################### HELPERS ###################################

# Debug mode > enable fd 3
if [[ $MSM_DEBUG ]]; then exec 3>&1; else exec 3>/dev/null; fi


# log to given MSM_LOGFILE or pass output through
log () { tee -a $MSM_LOGFILE; }


# indent output by 4 characters
indent () { sed 's/^/    /'; }


# print a 'stack trace'
trace () {
	local i=1
	while [[ ${FUNCNAME[$i]} != main ]] && (( i < ${#FUNCNAME[@]} )); do
		local func=${FUNCNAME[$i+1]}
		local line=${BASH_LINENO[$i]}
		case $func in
			( command_not_found_handle ) ;;
			( * )
				if [[ $not_first ]]; then printf "\n             "; fi
				printf "in %-40s (line %3s)" $func $line
				local not_first=1;;
		esac
		(( i++ ))
	done
}


# Make **text framed in double stars** bold
bold () { perl -0777 -pe 's/\*\*(.*?)\*\*/\*\*\x1b[1m$1\x1b[22m\*\*/gs'; }




############################### OUTPUT FUNCTIONS ###############################

fatal () {
	printf "\x1b[35m" >&2

	{	printf "**FATAL:**   "; trace; echo
		fmt -w67 | indent;						} | log | bold >&2

	printf "\x1b[m" >&2
	false
}

error () {
	printf "\x1b[31m" >&2

	{	printf "**ERROR:**   "; trace; echo
		fmt -w67 | indent;						} | log | bold >&2

	printf "\x1b[m" >&2
	false
}

warning () {
	printf "\x1b[33m"

	{	printf "**WARNING:** "; trace >&3; echo
		fmt -w67 | indent;						} | log | bold

	printf "\x1b[m"
}

info () {
	printf "\x1b[36m"

	{	printf "**INFO:**    "; trace >&3; echo
		fmt -w67 | indent;						} | log | bold

	printf "\x1b[m"
}

success () {
	printf "\x1b[32m"

	{	printf "**SUCCESS:** "; trace >&3; echo
		fmt -w67 | indent;						} | log | bold

	printf "\x1b[m"
}

debug () {
	printf "\x1b[34m" >&3

	{	printf "**DEBUG:**   "; trace; echo
		fmt -w67 | indent;						} | log | bold >&3

	printf "\x1b[m" >&3
}


# Regular output with logging and formatting
out () {
	log | bold
}