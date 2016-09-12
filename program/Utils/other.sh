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




# Search if an element is in an array
# Syntax: array-contains "${arr[*]}" elem
array-contains () {
	[[ " $1 " =~ " $2 " ]]
}

# Remove Elements in $2 from $1, Result is echoed
array-diff () {
	local elem
	local arr=" $1 "
	for elem in $2; do
		arr=${arr// $elem / }; done
	echo $arr
}

# Reverses the array of parameters given to this function.
# May break with large arrays due to the recursive nature
array-reverse () {
	[[ $1 ]] &&	echo $(array-reverse ${@:2}) $1
}

# kills and deletes the tmux-session at location $SOCKET
delete-tmux () {
	tmux -S "$SOCKET" kill-server > /dev/null 2>&1
	rm $SOCKET > /dev/null 2>&1
	return 0
}

fix-permissions () {
	source "$SUBSCRIPT_DIR/permissions.sh" 2> /dev/null
	# Errors are ignored and expected, as not all accessed files are
	# necessarily ours, some files may not exist at all.
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





########################## GENERAL SCRIPT CONFIGURATION ##########################






################################ DIRECTORY CHECKS ################################

# Checks existing data in INSTANCE_DIR, and prints appropriate warnings
# if data would have to be deleted
# Returns 0  if it is an empty directory
#         1  if it contains data
#         23 if it is not a directory or the user has insufficient access rights 
check-instance-dir () {
	[[ -e $INSTANCE_DIR ]] && {
		if ! [[ -d $INSTANCE_DIR ]]; then
			caterr <<-EOF
				$(bold ERROR:) $(bold "$INSTANCE_DIR") is not a directory! Move the file and try again.

				EOF
			return 23; fi

		if ! [[ -r $INSTANCE_DIR && -w $INSTANCE_DIR && -x $INSTANCE_DIR ]]; then
			caterr <<-EOF
				$(bold ERROR:) You do not have the necessary privileges to create a server instance
				       in $(bold "$INSTANCE_DIR")!

				EOF
			return 23; fi

		if ! [[ $(ls -A "$INSTANCE_DIR") ]]; then return 0; fi
		
		if ! [[ $(cat $INSTANCE_DIR/msm.d/appid 2> /dev/null) == $APPID ]]; then
			catwarn <<-EOF
				$(bold WARN:)  The directory $(bold "$INSTANCE_DIR") already contains data,
				       which may or may not be game server data. Please backup any important
				       files before proceeding!

				EOF
			return 1; fi

		if ! [[ -e $INSTANCE_DIR/msm.d/is-admin ]]; then # Is an instance, but not an admin
			catwarn <<-EOF
				$(bold WARN:)  A game instance already exists at $(bold "$INSTANCE_DIR").
				       Please backup any important files before proceeding!

				EOF
			return 1; fi
	}
	return 0
}
