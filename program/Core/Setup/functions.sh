#! /bin/bash

# (C) 2016 Maximilian Wende <maximilian.wende@gmail.com>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0






################################ CONFIG HANDLING ################################

Core.Setup::loadConfig () {
	# If given, read from file $1, otherwise the user's config file
	local CFG=${1-"$USER_DIR/$APP/msm.conf"}
	[[ -r $CFG ]] && {
		source $CFG && Core.Setup::validateConfig \
					|| error <<< "One or more errors were found in the configuration file $(bold "$CFG")!"
	}
}

# load msm configuration file of the given user
Core.Setup::loadConfigOf () {
	Core.Setup::loadConfig "$(eval echo ~$1)/msm.d/$APP/msm.conf"
}



# Check the current configuration variables for correctness and plausibility
Core.Setup::validateConfig () {
	local err=0
	# Require admin variable
	[[ $ADMIN ]] || error <<< "variable \$ADMIN is not defined!" || err=1

	# If admin, check the SteamCMD directory
	[[ $USER != $ADMIN ]] || { {
		[[ $STEAMCMD_DIR ]] || \
			error <<< "variable \$STEAMCMD_DIR is not defined!"
	} && {
		[[ -x $STEAMCMD_DIR/steamcmd.sh ]] || \
			error <<< "$(bold "$STEAMCMD_DIR") does not contain a valid SteamCMD installation!"
	} } || err=1

	# Check base installation directory
	{
		[[ $INSTALL_DIR ]] || \
			error <<< "variable \$INSTALL_DIR is not defined!"
	} && {
		[[ -r $INSTALL_DIR && -x $INSTALL_DIR ]] || \
			error <<< "The base installation directory $(bold "$INSTALL_DIR") is not accessible!"
	} && {
		[[ $(cat "$INSTALL_DIR/msm.d/appname" 2>/dev/null) == $APP && -e "$INSTALL_DIR/msm.d/is-admin" ]] || \
			error <<< "The directory $(bold "$INSTALL_DIR") is not a valid base installation for $APP!"
	} || err=1
	return $err
}




##################################### SETUP #####################################

Core.Setup::beginSetup () {
	# First-time setup
	cat <<-EOF
		-------------------------------------------------------------------------------
		                CS:GO Multi-Mode Server Manager - Initial Setup
		-------------------------------------------------------------------------------

		It seems like this is the first time you use this script on this machine.
		Before advancing, be aware of a few things:

		>>  The configuration will be saved in the directory:
		        $(bold "$USER_DIR/$APP")

		    Make sure to backup any important data in this location.

		>>  For multi-user setups, this script, located at
		        $(bold "$THIS_SCRIPT")
		    must be readable for all users.

		EOF
	promptY || return

	# TODO: Rework question to ask for an import
	cat <<-EOF

		Please choose the user that is responsible for the game installation and
		updates on this machine. As long as the access rights are correctly set,
		this server will use the game data provided by that user, which makes
		re-downloading the game for multiple users unnecessary.

		EOF

	while [[ ! $ADMIN_HOME ]]; do
		read -p "Admin's username (default: $USER) " -r ADMIN
		
		if [[ ! $ADMIN ]]; then ADMIN=$USER; fi
		if [[ ! $(getent passwd $ADMIN) ]]; then
			error <<< "User $(bold $ADMIN) does not exist! Please specify a different admin."
			echo
			continue
			fi

		ADMIN_HOME=$(eval echo ~$ADMIN)
		if [[ ! -r $ADMIN_HOME ]]; then
			error <<-EOF
					That user's home directory $(bold "$ADMIN_HOME")
					is not readable! Please specify a different admin.

				EOF
			unset ADMIN_HOME; fi
		done
	echo

	# Do admin setup
	[[ $USER == $ADMIN ]] && { admin-install; return; }

	# Try client setup (copying the configuration from the selected admin user)
	client-install && return

	# If client installation fails (for instance, if the admin has no configuration himself)
	# try switching to the admin and performing the admin installation there
	warning <<-EOF
			User $(bold $ADMIN) does not currently have a valid admin
			configuration. You may now switch to the admin user in order
			to create an admin configuration on his account (Ctrl-D to cancel).
		EOF
	echo

	sudo -i -u $ADMIN "$THIS_SCRIPT" admin-install

	if (( $? )); then caterr <<-EOF
			$(bold ERROR:) Admin Installation for $(bold $ADMIN) failed!

			EOF
		return 1; fi

	# Try client installation again!
	if ! client-install; then caterr <<-EOF
			$(bold ERROR:) Client Installation failed!

			EOF
		return 1; fi
}

client-install () {
	echo "Trying to import settings from $(bold $ADMIN) ..."

	ADMIN_HOME=$(eval echo "~$ADMIN")
	if [[ ! -r $ADMIN_HOME ]]; then caterr <<-EOF
			$(bold ERROR:) The admin's home directory $(bold "$ADMIN_HOME") is not readable.

			EOF
		return 1; fi

	ADMIN_CFG="$(cfgfile $ADMIN_HOME)"
	readcfg "$ADMIN_CFG"
	if (( $? )); then echo; return 1; fi
	writecfg
	return 0
}

admin-install () {
	cat <<-EOF
		-------------------------------------------------------------------------------
		                  CS:GO Multi Server Manager - Admin Install
		-------------------------------------------------------------------------------

		Checking for an existing configuration ...
		EOF
	if readcfg 2> /dev/null; then
		if [[ $ADMIN == $USER ]]; then catwarn <<-EOF
				$(bold WARN:)  A valid admin configuration already exists for this user $(bold $ADMIN).
				       If you continue, the installation steps will be executed again.

				EOF
		else catwarn <<-EOF
				$(bold WARN:)  This user is currently configured as client of user $(bold $ADMIN).
				       If you continue, this user will create an own game installation instead.

				EOF
			fi
		promptN || { echo; return 1; }
		fi

	if [[ ! $APPNAME || ! $APPID ]]; then caterr <<-EOF
		$(bold ERROR:) APPNAME and APPID are not set! Check this script and your
		       configuration file and try again!
		EOF
		return 1; fi

	echo
	ADMIN=$USER
	ADMIN_HOME=~
	echo "You started the admin Installation for user $(bold $ADMIN)"
	echo "This will create a configuration file in the location:"
	echo "        $(bold "$CFG")"
	echo
	promptY || { echo; return 1; }
	echo

	############ STEAMCMD ############
	# Check for an existing SteamCMD
	if [[ -x $ADMIN_HOME/Steam/steamcmd/steamcmd.sh ]]; then
		STEAMCMD_DIR="$ADMIN_HOME/Steam/steamcmd"
		catinfo <<< "$(bold INFO:)  An existing SteamCMD was found in $(bold "$STEAMCMD_DIR")."
	else
		# Ask for the SteamCMD directory
		cat <<-EOF
			SteamCMD is required to install the game server and its updates. Please
			specify the directory (absolute or relative to your home directory)
			for SteamCMD to be installed in.

			EOF

		unset SUCCESS
		until [[ $SUCCESS ]]; do
			read -r -p "SteamCMD install directory (default: Steam/steamcmd) " STEAMCMD_DIR

			if [[ ! $STEAMCMD_DIR ]]; then
				STEAMCMD_DIR=Steam/steamcmd;
				fi
			if [[ ! $STEAMCMD_DIR =~ ^/ ]]; then
				STEAMCMD_DIR="$ADMIN_HOME/$STEAMCMD_DIR"
				fi

			# If steamcmd exists in the specified directory, nothing more to do
			if [[ -x $STEAMCMD_DIR/steamcmd.sh ]]; then break; fi
			if [[ $(ls -A "$STEAMCMD_DIR" 2>/dev/null) ]]; then catwarn <<-EOF
					$(bold WARN:)  The specified directory $(bold "$STEAMCMD_DIR")
					       is non-empty. Please backup any important data before proceeding
					       or choose another directory!
					EOF
				promptN "Use this directory for the SteamCMD installation?" && SUCCESS=1
			else SUCCESS=1; fi

			done
		fi

	# Download and install SteamCMD, only if SteamCMD does not already exist in the target directory.
	if [[ ! -x $STEAMCMD_DIR/steamcmd.sh ]]; then
		WDIR=$(pwd)
		mkdir -p "$STEAMCMD_DIR"
		cd "$STEAMCMD_DIR"
		echo "Installing SteamCMD to $(bold "$STEAMCMD_DIR") ..."

		unset SUCCESS
		until [[ $SUCCESS ]]; do
			wget https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
			if (( $? )); then
				caterr <<< "$(bold ERROR:) SteamCMD Download failed."
				if ! promptY "Retry?"; then echo; return 1; fi
			else
				local SUCCESS=1
				fi
			done

		echo
		echo "Extracting ..."
		tar xzvf steamcmd_linux.tar.gz
		rm steamcmd_linux.tar.gz &> /dev/null
		if [[ ! -x $STEAMCMD_DIR/steamcmd.sh ]]; then
			caterr <<< "$(bold ERROR:) SteamCMD installation failed."
			echo
			return 1; fi

		echo
		echo "Updating SteamCMD ..."
		echo "quit" | "$STEAMCMD_DIR/steamcmd.sh"
		echo
		echo
		echo "SteamCMD installed successfully."
		cd "$WDIR"
		fi

	############ GAME INSTALL DIRECTORY ############
	# check for an existing game installation
	if	[[		$(cat "$ADMIN_HOME/$APPNAME/msm.d/appid" 2> /dev/null) == $APPID	\
			&&	-e "$ADMIN_HOME/$APPNAME/msm.d/is-admin"							]]; then
		INSTALL_DIR="$ADMIN_HOME/$APPNAME"
		catinfo <<< "$(bold INFO:)  A previous game installation was found in $(bold "$INSTALL_DIR")."
	else
		echo
		cat <<-EOF
			Now, please select the base installation directory. This is the directory the
			server will be downloaded to, make sure that there is plenty of free space on
			the disk. Be aware that this directory will be made public readable, so other
			users on the system can create server instances based on it.
			EOF

		unset SUCCESS
		until [[ $SUCCESS ]]; do
			echo
			read -r -p "Game Server Installation Directory (default: $APPNAME) " INSTALL_DIR

			if [[ ! $INSTALL_DIR ]]; then 
				INSTALL_DIR="$APPNAME" 
				fi
			if [[ ! $INSTALL_DIR =~ ^/ ]]; then
				INSTALL_DIR="$ADMIN_HOME/$INSTALL_DIR"
				fi

			INSTANCE_DIR="$INSTALL_DIR" check-instance-dir

			errno=$?
			if (( $errno == 1 )); then
				catwarn <<-EOF
					       This operation may $(bold "DELETE EXISTING DATA") in $(bold "$INSTALL_DIR") ...

					EOF
				sleep 2
				promptN && SUCCESS=1
			elif (( $errno )); then
				caterr <<-EOF
					$(bold ERROR:) $(bold "$INSTALL_DIR") cannot be used as a base
					       installation directory!
					EOF
			else
				SUCCESS=1
				fi
			if [[ ! $SUCCESS ]]; then
				echo "Please specify a different directory."
				fi
		done
		mkdir -p "$INSTALL_DIR"
		fi

	echo
	echo "Preparing installation directories ..."

	INSTANCE_DIR="$INSTALL_DIR"

	# Create SteamCMD Scripts
	cat > "$STEAMCMD_DIR/update" <<-EOF
		login anonymous
		force_install_dir "$INSTALL_DIR" 
		app_update $APPID
		quit
		EOF

	cat > "$STEAMCMD_DIR/validate" <<-EOF
		login anonymous
		force_install_dir "$INSTALL_DIR" 
		app_update $APPID validate
		quit
		EOF

	cat > "$STEAMCMD_DIR/update-check" <<-EOF
		login anonymous
		app_info_update 1
		app_info_print 740
		quit
		EOF

	############ PREPARE MSM DIRECTORY ############

	# Create settings directory within INSTALL_DIR
	mkdir -p "$INSTALL_DIR/msm.d"

	echo "$APPID"   > "$INSTALL_DIR/msm.d/appid"
	echo "$APPNAME" > "$INSTALL_DIR/msm.d/appname"
	# Copy scripts, but do not overwrite existing files/modifications
	cp -n "$SUBSCRIPT_DIR/server.conf" "$INSTALL_DIR/msm.d/server.conf"
	cp -n -R "$THIS_DIR/modes-$APPID" "$INSTALL_DIR/msm.d/modes"
	cp -n -R "$THIS_DIR/addons-$APPID" "$INSTALL_DIR/msm.d/addons"


	touch "$INSTALL_DIR/msm.d/is-admin"

	fix-permissions

	# Create Config and make it readable
	writecfg
	chmod a+r "$CFG"

	cat <<-EOF
		Basic Setup Complete!

		Do you want to install/update the game right now? If you choose No, you can
		install the game later using '$THIS_COMM install' or copy the files manually.

		EOF

	if promptY "Install Now?"; then
		echo
		update
		return 0; fi

	echo
	return 0
}
