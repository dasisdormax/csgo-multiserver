#! /bin/bash

# (C) 2016 Maximilian Wende <maximilian.wende@gmail.com>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0






################################ CONFIG HANDLING ################################

requireConfig () {
	Core.Setup::validateConfig || error <<-EOF
		No valid configuration found!

		Try $(bold "$THIS_COMMAND setup") to create a new
		configuration.
	EOF
}

Core.Setup::loadConfig () {
	# If given, read from file $1, otherwise the user's config file
	local CFG=${1-"$USER_DIR/$APP/msm.conf"}
	[[ -r $CFG ]] && {
		if builtin . $CFG; then
			Core.Setup::validateConfig
		else
			error <<< "Configuration file $(bold "$CFG") could not be executed!"
		fi
	}
}


# load msm configuration file of the given user
Core.Setup::loadConfigOf () {
	Core.Setup::loadConfig "$(eval echo ~$1)/msm.d/$APP/msm.conf"
}


# Check the current configuration variables for correctness and plausibility
Core.Setup::validateConfig () {
	# Require admin variable
	[[ $ADMIN ]] || error <<< "variable \$ADMIN is not defined!" || return

	# If admin, check the SteamCMD directory
	if [[ $USER == $ADMIN ]]; then
		[[ $STEAMCMD_DIR                  ]] || error <<-EOF || return
				variable \$STEAMCMD_DIR is not defined!
			EOF
		[[ -x $STEAMCMD_DIR/steamcmd.sh   ]] || error <<-EOF || return
				$(bold "$STEAMCMD_DIR") does not contain a
				valid SteamCMD installation!
			EOF
	fi

	# Check base installation directory
	[[ $INSTALL_DIR                       ]] || error <<-EOF || return
			variable \$INSTALL_DIR is not defined!
		EOF

	[[ -r $INSTALL_DIR && -x $INSTALL_DIR ]] || error <<-EOF || return
			The base installation directory $(bold "$INSTALL_DIR")
			is not accessible!
		EOF

	[[ $(cat "$INSTALL_DIR/msm.d/appname" 2>/dev/null) == $APP    \
	   && -e "$INSTALL_DIR/msm.d/is-admin"                     ]] \
											 || error <<-EOF || return
			The directory $(bold "$INSTALL_DIR") is not a
			valid base installation for $APP!
		EOF
}


Core.Setup::writeConfig () {
	CFG_DIR="$USER_DIR/$APP"
	if Core.Setup::validateConfig; then
		Core.Setup::printConfig > "$CFG_DIR/msm.conf" || fatal <<-EOF
				Error writing the configuration to $(bold "$CFG_DIR/msm.conf")!
				You may lack the necessary permissions to access the file!
			EOF
	else
		error <<< "Invalid configuration!"
	fi
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




################################# SETUP HELPERS #################################

Core.Setup::importFrom () {
	local IMPORT_FROM=$1
	echo
	echo "Trying to import the configuration of user $(bold $IMPORT_FROM) ..."

	# Check if user exists and has a configuration

	local ADMIN_HOME="$(eval echo ~$IMPORT_FROM)"
	[[ -r $ADMIN_HOME ]] || error <<-EOF || return
			User $(bold $IMPORT_FROM) does not exist or their home
			directory is not readable!
		EOF

	[[ -r $ADMIN_HOME/msm.d/$APP/msm.conf ]] || {
		warning <<-EOF
			User $(bold $IMPORT_FROM) has no configuration that we can import settings
			from. You may, though, switch users and create a configuration on
			that user's account.

			You will have to confirm switching users with your sudo password. (CTRL-C to cancel)

		EOF

		sudo -i -u $IMPORT_FROM MSM_DO_INSTALL=1 "$THIS_SCRIPT" || {
			echo "Cancelling the import from user $IMPORT_FROM ..."
			return 1
		}
	}

	# Import their configuration
	Core.Setup::loadConfigOf $IMPORT_FROM || error <<-EOF || return
			The configuration of user $IMPORT_FROM contains errors!
		EOF

	if [[ $ADMIN != $IMPORT_FROM ]]; then
		echo "The configuration of user $IMPORT_FROM refers to user $ADMIN."
		echo "We will now try to import that user's configuration instead ..."
		Core.Setup::importFrom $ADMIN;
		return
	fi

	Core.Setup::writeConfig
}


Core.Setup::isExistingSteamCMD () {
	[[ -x $STEAMCMD_DIR/steamcmd.sh ]] && info <<< "SteamCMD was found in $(bold "$STEAMCMD_DIR")."
}
# installs SteamCMD into the directory specified by $STEAMCMD_DIR
# runs in a subshell to not modify the outer working directory
Core.Setup::installSteamCMD () (

	# if SteamCMD already exists, we have nothing to do
	Core.Setup::isExistingSteamCMD && return

	# Create the directory
	mkdir -p "$STEAMCMD_DIR" && [[ -w $STEAMCMD_DIR ]] || {
		fatal <<< "No permission to create or write the directory $(bold "$STEAMCMD_DIR")!"
		return
	}
	cd "$STEAMCMD_DIR"

	# Warn, if the directory already contains files
	[[ $(ls -A) ]] && {
		warning <<-EOF
				The directory $(bold "$STEAMCMD_DIR") is non-empty, installing
				SteamCMD to this location may cause $(bold "LOSS OF DATA")!

				Please backup all important files before proceeding!

			EOF
		sleep 2
		promptN || return
	}

	echo "Installing SteamCMD to $(bold "$STEAMCMD_DIR") ..."

	until wget "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz"; do
		echo "Download failed. Retrying ..."; sleep 5; done

	tar xzf steamcmd_linux.tar.gz
	rm steamcmd_linux.tar.gz &> /dev/null

	[[ -x steamcmd.sh ]] || error <<< "SteamCMD installation failed!" || return

	echo "Updating SteamCMD ..."
	$(which unbuffer) echo "quit" | steamcmd.sh; echo
	echo
	success <<< "SteamCMD installed successfully!"
)



################################# INITIAL SETUP #################################

Core.Setup::beginSetup () {
	cat <<-EOF
		-------------------------------------------------------------------------------
		                CS:GO Multi-Mode Server Manager - Initial Setup
		-------------------------------------------------------------------------------

		It seems like this is the first time you use this script on this machine.
		Before advancing, be aware of a few things:

		>>  The configuration files will be saved in the directory:
		        $(bold "$USER_DIR/$APP")

		    Make sure to backup any important data in that location.

		>>  For multi-user setups, this script, located at
		        $(bold "$THIS_SCRIPT")
		    must be readable for all users.

	EOF

	promptY || return

	# Create config directory
	local CFG_DIR="$USER_DIR/$APP"
	mkdir -p "$CFG_DIR" && [[ -w "$CFG_DIR" ]] || {
		fatal <<< "No permission to create or write the directory $(bold "$CFG_DIR")!"
		return
	}

	# Check, if config is writable
	[[ ! -r "$CFG_DIR/msm.conf" || -w "$CFG_DIR/msm.conf" ]] || {
		fatal <<< "No permission to write the configuration file $(bold "$CFG_DIR/msm.conf")!"
		return
	}

	# Ask the user if they wish to import a configuration
	if [[ ! $ADMIN ]]; then
		echo "Importing configurations"
		echo "========================"
		echo
		fmt -w67 <<-EOF | indent
			Instead of creating a new configuration, you may also import the settings
			from a different user on this system. This allows you to use that user's game
			server installation as a base for your own instances, without having to
			download the server files again.

			If you wish to import the settings from another user, enter their name below.
			Otherwise, hit enter to create your own configuration.

		EOF
	fi

	local SUCCESS=
	until [[ $SUCCESS ]]; do
		if [[ ! $ADMIN ]]; then
			echo "Please enter the user to import the configuration from. Leave empty to"
			echo "skip importing configurations, press CTRL-C to exit."
			echo
			read -p "> Import configuration from? " -r ADMIN
		fi

		ADMIN=${ADMIN:-$USER}

		[[ $ADMIN == $USER ]] && { Core.Setup::setupAsAdmin; return; }

		if Core.Setup::importFrom $ADMIN; then
			success <<< "The configuration of user $(bold $ADMIN) has been imported successfully!"
			local SUCCESS=1
		else
			warning <<< "Import failed! Please specify a different user."
			ADMIN=
		fi

		echo
	done

	# Succeeds, if we have a valid config at the end
	Core.Setup::loadConfig
}




############################### ADMIN INSTALLATION ##############################

# TODO: make this function smaller
Core.Setup::setupAsAdmin () {

	cat <<-EOF

		Basic Setup
		===========

	EOF

	fmt -w67 <<-EOF | indent
		Now, we will install all dependencies and prepare an initial
		game server installation. Please follow the instructions below.

	EOF

	######### Install STEAMCMD

	STEAMCMD_DIR="$HOME/Steam/steamcmd"
	until Core.Setup::isExistingSteamCMD; do
		# Ask for the SteamCMD directory
		cat <<-EOF
			SteamCMD is required to install the game server and its updates. Please
			select a directory (absolute or relative to your home directory)
			for SteamCMD to be installed in.

		EOF

		read -r -p "SteamCMD install directory (default: Steam/steamcmd) " STEAMCMD_DIR

		STEAMCMD_DIR=${STEAMCMD_DIR:-"Steam/steamcmd"}
		[[ $STEAMCMD_DIR =~ ^/ ]] || STEAMCMD_DIR="$HOME/$STEAMCMD_DIR"

		Core.Setup::installSteamCMD && echo && break
	done

	######### Create base installation

	############ GAME INSTALL DIRECTORY ############
	# check for an existing game installation

	INSTALL_DIR="$HOME/$APP"
	until Core.BaseInstallation::isExisting; do
		cat <<-EOF
			Now, please select the base installation directory. This is the directory the
			server will be downloaded to, make sure that there is plenty of free space on
			the disk. Be aware that this directory will be made public readable, so other
			users on the system can create server instances based on it.

		EOF

		read -r -p "Game Server Installation Directory (default: $APP) " INSTALL_DIR

		INSTALL_DIR=${INSTALL_DIR:-"$APP"}
		[[ $INSTALL_DIR =~ ^/ ]] ||	INSTALL_DIR="$HOME/$INSTALL_DIR"

		Core.BaseInstallation::create && echo && break
	done


	############# TODO: Let app provide and copy those scripts ############
	# cp -n "$SUBSCRIPT_DIR/server.conf" "$INSTALL_DIR/msm.d/server.conf"
	# cp -n -R "$THIS_DIR/modes-$APPID" "$INSTALL_DIR/msm.d/modes"
	# cp -n -R "$THIS_DIR/addons-$APPID" "$INSTALL_DIR/msm.d/addons"

	################### Should not be necessary anymore ###################
	# fix-permissions

	# Create Config and make it readable
	chmod o+rx "$USER_DIR"
	Core.Setup::writeConfig && chmod -R o+rx "$USER_DIR/$APP" && success <<-EOF
			Basic Setup Complete!

			Execute '$THIS_COMMAND install' to install or update the actual game files
			through SteamCMD. Of course, you can also copy the files from a different
			location.

			Use '$THIS_COMMAND @name create' to create a new server instance out of
			your base installation. You may modify each instance's settings independently
			from the others.

		EOF
}