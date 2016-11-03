#! /bin/bash

# (C) 2016 Maximilian Wende <maximilian.wende@gmail.com>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0




############################### COMMON VARIABLES ################################

THIS_DIR="$(dirname "${BASH_SOURCE[0]}")"

USER=$(whoami) # just in case
USER_DIR="$HOME/msm.d"




############################### COMMON FUNCTIONS ################################

# override dot builtin: execute a handler (either a .sh-file or .sh-files in a directory)
# Further parameters are passed to the executed scripts
. () {
	local cmd="${1%%.sh}" # Strip .sh extension
	# Try executing file or file.sh (depending on extension) otherwise execute sh-files in directory
	if [[ $cmd =~ \.[^/]*$ ]]; then
		.file "$cmd"    "${@:2}" && return
	else
		.file "$cmd.sh" "${@:2}" && return
	fi
	.dir "$cmd" "${@:2}"
}


# Execute all .sh-files inside a given directory
# Further parameters are passed to the executed scripts
#
# Returns
#   true,  if all files in the directory $1 could be executed
#   false, - if $1 is no directory or contains no .sh files
#          - if errors occured during the execution of any file
.dir () {
	[[ -d $1 ]] && {
		for file in "$1"/*.sh; do
			.file "$file" "${@:2}" || return
		done
	}
}


# Execute a file and set the context for the colon function
# Further parameters are passed to the executed scripts
.file () { [[ -f $1 ]] && builtin . "$@"; }


# .conf function: execute a config file, preferring user config over global config
.conf () { . "$USER_DIR/$@" || . "$THIS_DIR/$@"; }


# override colon builtin: execute a file relative to the current file's base directory
# Further parameters are passed to the executed scripts
: () {
	CURR_DIR="$(dirname "$(readlink -e "${BASH_SOURCE[1]}")")"
	. "$CURR_DIR/$@"
}




########################## LOAD GENERAL CONFIGURATION ##########################

# This sets the default parameters such as $APP, if not given through the environment
.conf "cfg/defaults.conf"
