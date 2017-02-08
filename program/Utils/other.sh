#! /bin/bash

# (C) 2016 Maximilian Wende <maximilian.wende@gmail.com>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0




###############################################
#                                             #
#  TODO: Move these functions to other files  #
#                                             #
###############################################


################################ HELPER FUNCTIONS ################################




# Search if an element is in a list
# Usage: list-contains "$list" $elem
list-contains () {
	[[ " $1 " =~ " $2 " ]]
}


# Remove Elements from a list, Result is echoed
# Usage: diff="$(list-diff "$list" $elems_to_remove)"
list-diff () {
	local elem
	list=" $1 "
	for elem in ${*:2}; do
		list=${list// $elem / }; done # Replace " $elem " with " "
	echo "$list"
}


# Reverses the list of parameters given to this function.
# May break with large arrays due to the recursive nature
# Usage: revList="$(list-reverse $list)"
list-reverse () {
	[[ $1 ]] &&	echo $(list-reverse ${@:2}) $1
}


# kills and deletes the tmux server with socket $SOCKET
kill-tmux () {
	tmux -S "$SOCKET" kill-server
	rm "$SOCKET"
} > /dev/null 2>&1


# Syntax: echo "Hello" | tmux-send -t target
tmux-send () {
	tmux -S "$SOCKET" send-keys $@ -l "$(cat)"
	tmux -S "$SOCKET" send-keys $@ enter
}


timestamp () { date +%y%m%d_%T; }


try () { declare -f -F "$1" >/dev/null && "$@"; }


# Output an array of arguments as a shell-quoted string
quote () {
	local args=( )
	local a
	while (( $# )); do
		a=${1//\"/'\"'}
		a=${a//\$/'\$'}
		[[ ! $a || "$a" =~ [[:space:]] ]] && a="\"$a\""
		args+=( "$a" )
		shift
	done
	echo "${args[@]}"
}


ssh-pass-vars () {
	local var
	for var; do
		echo "${!var+"$var=${!var}"}"
	done
}
