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

# kills and deletes the tmux-session at location $SOCKET
delete-tmux () {
	tmux -S "$SOCKET" kill-server > /dev/null 2>&1
	rm $SOCKET > /dev/null 2>&1
	return 0
}

# Sets the instance to the value of $1
set-instance () {
	INSTANCE="$1"
	if [[ $INSTANCE ]];
	then
		INSTANCE_DIR="$HOME/$APPNAME@$INSTANCE"
		SERVER_TEXT="Server Instance $(bold "@$INSTANCE")"
	else
		INSTANCE_DIR="$INSTALL_DIR"
		SERVER_TEXT="$(bold "Base Installation")"
		fi
	SOCKET="$INSTANCE_DIR/msm.d/tmp/server.tmux-socket"
}


timestamp () { date +%y%m%d_%T; }