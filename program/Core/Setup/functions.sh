#! /bin/bash

# (C) 2016 Maximilian Wende <maximilian.wende@gmail.com>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0




Core.Setup::registerCommands () {
	simpleCommand "Core.Setup::beginSetup" setup
	simpleCommand "Core.Setup::printConfig" print-config
}




################################ CONFIG HANDLING ################################

requireConfig () {
	Core.Setup::validateConfig || error <<-EOF
		No valid configuration found!

		Create a new configuration using **$THIS_COMMAND setup**.
	EOF
}


requireAdmin () {
	requireConfig || return
	[[ $USER == $ADMIN ]] || error <<-EOF
		The user **$ADMIN** controls the base installation exclusively
		and is the only one who can perform actions on it!
	EOF
}


Core.Setup::loadConfig () {
	.conf "cfg/app-$APP.conf" && Core.Setup::validateConfig
}


# load msm configuration file of the given user
Core.Setup::loadConfigOf () {
	USER_DIR="$(eval echo ~$1)/msm.d" Core.Setup::loadConfig
}


# Check the current configuration variables for correctness and plausibility
Core.Setup::validateConfig () {
	# Require admin variable
	[[ $ADMIN ]] || error <<< "variable \$ADMIN is not defined!" || return

	# Check base installation directory
	[[ $INSTALL_DIR                       ]] || error <<-EOF || return
			variable \$INSTALL_DIR is not defined!
		EOF

	[[ -r $INSTALL_DIR && -x $INSTALL_DIR ]] || error <<-EOF || return
			The base installation directory **$INSTALL_DIR**
			is not accessible!
		EOF

	INSTANCE_DIR="$INSTALL_DIR" Core.Instance::isBaseInstallation \
											 || error <<-EOF || return
			The directory **$INSTALL_DIR** is not a
			valid base installation for $APP!
		EOF
}


Core.Setup::writeConfig () {
	CFG="$USER_DIR/cfg/app-$APP.conf"
	if Core.Setup::validateConfig; then
		Core.Setup::printConfig > "$CFG" || fatal <<-EOF
				Error writing the configuration to **$CFG**!
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

	App::printAdditionalConfig
}




################################# SETUP HELPERS #################################

Core.Setup::importFrom () {
	local IMPORT_FROM=$1
	out <<< ""
	out <<< "Trying to import the configuration of user **$IMPORT_FROM** ..."

	# Check if user exists and has a configuration

	local ADMIN_HOME="$(eval echo ~$IMPORT_FROM)"
	[[ -r $ADMIN_HOME ]] || error <<-EOF || return
			User **$IMPORT_FROM** does not exist or their home
			directory is not readable!
		EOF

	[[ -r $ADMIN_HOME/msm.d/cfg/app-$APP.conf ]] || {
		warning <<-EOF
			User **$IMPORT_FROM** has no configuration that we can import settings
			from. You may, though, switch users and create a configuration on
			that user's account.

			You will have to confirm switching users with your sudo password. (CTRL-C to cancel)

		EOF

		sudo -iu $IMPORT_FROM \
			MSM_LOGFILE="$MSM_LOGFILE" MSM_DEBUG=$MSM_DEBUG ADMIN=$ADMIN \
			"$THIS_COMMAND" setup ||
		{
			out <<< "Cancelled the import from user $IMPORT_FROM ..."
			return 1
		}
	}

	# Import their configuration
	Core.Setup::loadConfigOf $IMPORT_FROM || error <<-EOF || return
			The configuration of user $IMPORT_FROM contains errors!
		EOF

	if [[ $ADMIN != $IMPORT_FROM ]]; then
		info <<-EOF
			The configuration of user $IMPORT_FROM refers to user $ADMIN.
			We will now try to import that user's configuration instead ...
		EOF
		Core.Setup::importFrom $ADMIN;
		return
	fi

	Core.Setup::writeConfig
}




################################# INITIAL SETUP #################################

Core.Setup::beginSetup () {
	out <<-EOF

		-------------------------------------------------------------------------------
		                CS:GO Multi-Mode Server Manager - Initial Setup
		-------------------------------------------------------------------------------

		It seems like this is the first time you use this script on this machine.
		Before advancing, be aware of a few things:

		>>  The configuration files will be saved in the directory:
		        **$USER_DIR/cfg**

		    Make sure to backup any important data in that location.

		>>  For multi-user setups, this script, located at
		        **$THIS_SCRIPT**
		    must be readable for all users.
	EOF

	promptY || return

	# Create config directory
	local CFG_DIR="$USER_DIR/cfg"
	local CFG="$CFG_DIR/app-$APP.conf"
	mkdir -p "$CFG_DIR" && [[ -w "$CFG_DIR" ]] || {
		fatal <<< "No permission to create or write the directory **$CFG_DIR**!"
		return
	}

	# Check, if config is writable
	[[ ! -e "$CFG" || -w "$CFG" ]] || {
		fatal <<< "No permission to write the configuration file **$CFG**!"
		return
	}

	# Ask the user if they wish to import a configuration
	if [[ ! $ADMIN ]]; then
		log <<-EOF

			Importing configurations
			========================
		EOF
		fmt -w67 <<-EOF | indent

			Instead of creating a new configuration, you may also import the settings
			from a different user on this system.  This allows you to use that user's
			game server installation as a base for your own instances, without having
			to download the server files again.

			If you wish to import the settings from another user, enter their name below.
			Otherwise, hit enter to create your own configuration.
		EOF
	fi

	local SUCCESS=
	until [[ $SUCCESS ]]; do
		if [[ ! $ADMIN ]]; then
			echo
			echo "Please enter the user to import the configuration from.  Leave empty"
			echo "to skip importing configurations, press CTRL-C to exit."
			echo
			read -p "> Import configuration from? " -r ADMIN

			if [[ $ADMIN ]]; then
				debug <<< "Selected to import from user **$ADMIN**."
			else
				ADMIN=$USER
				debug <<< "Skipping import and starting admin setup."
			fi
		fi

		[[ $ADMIN == $USER ]] && { Core.Setup::setupAsAdmin; return; }

		if Core.Setup::importFrom $ADMIN; then
			success <<< "The configuration of user **$ADMIN** has been imported successfully!"
			local SUCCESS=1
		else
			warning <<< "Import failed! Please specify a different user."
			ADMIN=
		fi
	done

	# Succeeds, if we have a valid config at the end
	Core.Setup::loadConfig
}




############################### ADMIN INSTALLATION ##############################

# TODO: make this function smaller
Core.Setup::setupAsAdmin () {

	log <<-EOF

		Basic Setup
		===========

		This assistant will install all remaining dependencies for your
		$APP server and create a basic configuration.  Please follow the
		instructions below.
	EOF

	######### Install App Downloader/Updater

	App::installUpdater || return

	######### Create base installation

	INSTANCE=
	INSTALL_DIR="$HOME/$APP-base"
	until Core.BaseInstallation::isExisting; do
		bold <<-EOF

			Now, please select the **base installation directory**.  This is the
			directory the server will be downloaded to, make sure that there is
			plenty of free space on the disk.  Be aware that this directory will
			be made **public readable**, so other users on the system can create
			server instances based on it.

		EOF

		read -r -p "Game Server Installation Directory (default: ~/$APP-base) " INSTALL_DIR

		INSTALL_DIR=${INSTALL_DIR:-"$HOME/$APP-base"}
		INSTALL_DIR="$(eval echo "$INSTALL_DIR")"   # expand tilde and stuff
		INSTALL_DIR="$(readlink -m "$INSTALL_DIR")" # get absolute directory

		Core.BaseInstallation::create
	done

	# Final Steps
	App::finalizeInstance
	Core.BaseInstallation::applyPermissions

	# Create Config and make it readable
	chmod o+rx "$USER_DIR" "$CFG_DIR"
	Core.Setup::writeConfig && {
		log <<< ""
		success <<-EOF
			Basic Setup Complete!

			Execute **$THIS_COMMAND install** to install or update the actual game files.
			Of course, you can also copy the files from a different location.

			Use **$THIS_COMMAND @name create** to create a new server instance out of
			your base installation.  Each instance can be configured independently and
			multiple instances can run simultaneously.
		EOF
	}
	chmod o+rX "$CFG"
}