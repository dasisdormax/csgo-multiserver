#! /bin/bash

# (C) 2016 Maximilian Wende <maximilian.wende@gmail.com>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0




################################ HELPER FUNCTIONS ################################

# A yes/no prompt. With the first parameter $1, an alternative prompt message can be given.
# returns true (0) for yes, and false (1) for no. Defaults to YES
promptY () {
	local PROMPT="Proceed?"
	if [[ $1 ]]; then local PROMPT="$1"; fi

	read -r -p "$PROMPT ($(bold Y)/n) " INPUT
	# Implicit return value below
	[[ ! $INPUT || $INPUT =~ ^([Yy]|[Yy][Ee][Ss])$ ]]
}

# A similar prompt that defaults to NO instead
promptN () {
	local PROMPT="Are you sure?"
	if [[ $1 ]]; then local PROMPT="$1"; fi
	printf "\x1b[33m"
	read -r -p "$PROMPT (y/$(bold N)) " INPUT
	printf "\x1b[m"
	# Implicit return value below
	[[ $INPUT =~ ^([Yy]|[Yy][Ee][Ss])$ ]]
}

# kills and deletes the tmux-session at location $SOCKET
delete-tmux () {
	tmux -S "$SOCKET" kill-server > /dev/null 2>&1
	rm $SOCKET
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

caterr  () { printf "\x1b[31m" 1>&2; cat 1>&2; printf "\x1b[m" 1>&2; }

catwarn () { printf "\x1b[33m" 1>&2; cat 1>&2; printf "\x1b[m" 1>&2; }

catinfo () { printf "\x1b[36m"     ; cat     ; printf "\x1b[m"     ; }

# Make text $1 bold
bold () { printf "\x1b[1m%s\x1b[22m" "$1"; }




########################## GENERAL SCRIPT CONFIGURATION ##########################

# Get absolute config file location, based on MSM_CFG
# $1 is the base directory, if omitted, the current home directory is taken
cfgfile () {
	if [[ $MSM_CFG =~ ^/ ]]; then
		local CFG="$MSM_CFG"
	else
		if [[ $1 ]]; then
			echo "$1/$MSM_CFG"
		else
			echo "$HOME/$MSM_CFG"
			fi
		fi
}

# Check environment variables for correctness
# If an argument $1 is given, these variables are checked for that user instead of the current one
checkvars () {
	if [[ $1 ]]; then local USER="$1"; fi
	if [[ ! $ADMIN ]]; then
		caterr <<< "$(bold ERROR:) ADMIN is not defined!"
		return 1; fi

	if [[ $USER == $ADMIN && ( ! $STEAMCMD_DIR || ! -x $STEAMCMD_DIR/steamcmd.sh ) ]]; then
		caterr <<< "$(bold ERROR:) STEAMCMD_DIR is not defined or steamcmd.sh was not found in it!"
		return 1; fi

	if [[ ! $INSTALL_DIR ]]; then
		caterr <<< "$(bold ERROR:) INSTALL_DIR is not defined!"
		return 1; fi

	if [[ ! -r $INSTALL_DIR ]]; then
		caterr <<< "$(bold ERROR:) $(bold "$INSTALL_DIR") does not exist or is not readable!"
		return 1; fi

	if [[ $(cat "$INSTALL_DIR/msm.d/appid" 2> /dev/null) != $APPID || ! -e "$INSTALL_DIR/msm.d/is-admin" ]]; then
		caterr <<-EOF
			$(bold ERROR:) The directory $(bold "$INSTALL_DIR")
			       is not a valid base installation for $APPNAME!
			EOF
		return 1; fi

	return 0
}

# reads the user's configuration file or the file given with $1
readcfg () {
	if [[ $1 ]]; then local CFG="$1"; fi
	if [[ -r $CFG ]]; then
		source "$CFG" # this isn't great, as a config file of a different user can potentially be malicious
		checkvars || {
			caterr <<< "$(bold ERROR:) One or more errors in the configuration file $(bold "$CFG")!"
			return 1
		}
		return 0; fi

	caterr <<< "$(bold ERROR:) Configuration file $(bold "$CFG") does not exist!"
	return 1
}

# prints the variable values for the config file
printcfg () {
	cat <<-EOF
		#! /bin/bash
		# This is a configuration file for CS:GO Multi Server Manager
		ADMIN=$ADMIN
		INSTALL_DIR="$INSTALL_DIR"
		DEFAULT_INSTANCE="$DEFAULT_INSTANCE"
		EOF
	# Vars that are only interesting for the admin
	if [[ $USER == $ADMIN ]]; then cat <<-EOF
		STEAMCMD_DIR="$STEAMCMD_DIR"
		EOF
		fi
}

# Write configuration file for the current user
writecfg () {
	CFG=$(cfgfile)
	echo "Creating CS:GO MSM Config File in $(bold "$CFG") ..."
	checkvars || { echo; return 1; }

	rm $CFG > /dev/null 2>&1
	printcfg > $CFG
	echo
}




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