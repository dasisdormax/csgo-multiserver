#! /bin/bash

# (C) 2016 Maximilian Wende <maximilian.wende@gmail.com>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0




###########################################
#                                         #
#  NOTE: These functions may rather be    #
#        placed in the Core.Setup module  #
#                                         #
###########################################




# Get absolute config file location, based on MSM_CFG
# relative to either the home directory or the given directory $1
cfgfile () {
	if [[ $1 ]]; then
		echo "$1/$MSM_CFG"
	else
		echo "$HOME/$MSM_CFG"; fi
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
