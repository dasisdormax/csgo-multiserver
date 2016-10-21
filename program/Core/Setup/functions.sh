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


Core.Setup::writeConfig () {
	local CFG_DIR="$USER_DIR/$APP"
	Core.Setup::validateConfig && {
		mkdir -p "$CFG_DIR" || error <<< "Could not create configuration directory $(bold "$CFG_DIR")!"
	} && {
		Core.Setup::printConfig > "$CFG_DIR/msm.conf" || error <<< "Could not write to configuration file $(bold "$CFG_DIR/msm.conf")!"
	}
}

Core.Setup::printConfig () {
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

##################################### SETUP #####################################

Core.Setup::beginSetup () {
	# First-time setup
	cat <<-EOF
			-------------------------------------------------------------------------------
			                CS:GO Multi-Mode Server Manager - Initial Setup
			-------------------------------------------------------------------------------

			It seems like this is the first time you use this script on this machine.
			Before advancing, be aware of a few things:

			>>  The configuration files will be saved in the directory:
			        $(bold "$USER_DIR/$APP")

			    Make sure to backup any important data in this location before proceeding.

			>>  For multi-user setups, this script, located at
			        $(bold "$THIS_SCRIPT")
			    must be readable for all users.

		EOF
	promptY || return

	if [[ ! $ADMIN ]]; then
		cat <<-EOF
				IMPORTING
				=========

				Instead of creating a new configuration, you may also import the settings
				from a different user on this system. This allows you to use that user's game
				server installation as a base for your own instances, without having to
				download the server files again.

				If you wish to import the settings from another user, enter their name below.
				Otherwise, hit enter to create your own configuration.

			EOF

		until [[ $ADMIN ]]; do
			echo "Please enter the user to import the configuration from."
			echo "Leave empty to skip importing, Press CTRL-C to exit."
			read -p "> Import configuration from? " -r ADMIN

			if [[ $ADMIN ]]; then
				if Core.Setup::importFrom $ADMIN; then
					info <<< "The configuration was successfully imported from user $(bold $ADMIN)"
					return
				else error <<-EOF || ADMIN=
						Import from user $ADMIN failed! Please specify a different user.
					EOF
					fi
			else
				ADMIN=$USER; fi
			done; fi

	# Do admin setup
	[[ $USER == $ADMIN ]] && admin-install

	# Succeeds, if we have a valid config at the end
	Core.Setup::loadConfig
}


Core.Setup::importFrom () {
	local IMPORT_FROM=$1
	echo "Trying to import the configuration of user $(bold $IMPORT_FROM)"

	# Check if user exists and has a configuration
	local ADMIN_HOME="$(eval echo ~$IMPORT_FROM)"
	[[ -r $ADMIN_HOME ]] || error <<< "User $(bold $IMPORT_FROM) does not exist or their home directory is not readable!" || return

	[[ -r $ADMIN_HOME/msm.d/$APP/msm.conf ]] || {
		warning <<-EOF
			User $(bold $IMPORT_FROM) has no configuration that we can import settings
			from. You may, though, switch users and create a configuration on
			that user's account.

			You will have to confirm switching users with your sudo password.
			Press CTRL-D to cancel.

		EOF

		ADMIN=$IMPORT_FROM sudo -i -u $IMPORT_FROM "$THIS_SCRIPT" || {
			info <<< "Cancelled creating a configuration for user $IMPORT_FROM."
			return 1
		}
	}

	# Import their configuration
	Core.Setup::loadConfigOf $IMPORT_FROM || error <<-EOF || return
			The configuration of user $IMPORT_FROM contains errors!
		EOF

	if [[ $ADMIN != $IMPORT_FROM ]]; then
		Core.Setup::importFrom $ADMIN;
		return; fi

	Core.Setup::writeConfig
}


# TODO: make this function smaller
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
