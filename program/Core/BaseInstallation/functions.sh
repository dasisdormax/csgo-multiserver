#! /bin/bash

# (C) 2016 Maximilian Wende <maximilian.wende@gmail.com>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0




########################### CREATING A BASE INSTALLATION ##########################

Core.BaseInstallation::isExisting () {
	INSTANCE_DIR=$INSTALL_DIR Core.Instance::isBaseInstallation && \
		info <<< "An existing base installation was found in **$INSTALL_DIR**"
}


# creates a base installation in the directory specified by $INSTALL_DIR
Core.BaseInstallation::create () (

	Core.BaseInstallation::isExisting && return

	umask o+rx # make sure that other users can 'fork' this base installation
	INSTANCE_DIR="$INSTALL_DIR"

	Core.Instance::isValidDir || {
		warning <<-EOF
			The directory **$INSTALL_DIR** is non-empty, creating a base
			installation here may cause **LEAKAGE OR LOSS OF DATA**!

			Please backup all important files before proceeding!

		EOF
		sleep 2
		promptN || return
	}

	# Create base installation directory
	mkdir -p "$INSTALL_DIR" && [[ -w "$INSTALL_DIR" ]] || {
		fatal <<< "No permission to create or write the directory **$INSTALL_DIR**!"
		return
	}

	# Make existing files readable for other users
	chmod -R +rX "$INSTALL_DIR"

	# Delete old configuration
	rm -rf "$INSTALL_DIR/msm.d" 2>/dev/null

	# Create new configuration
	mkdir "$INSTALL_DIR/msm.d"
	echo "$APP" > "$INSTALL_DIR/msm.d/app"
	touch "$INSTALL_DIR/msm.d/is-admin" # Mark as base installation

	# Create temporary and logging directories
	mkdir "$INSTALL_DIR/msm.d/tmp"
	mkdir "$INSTALL_DIR/msm.d/log"
)




########################### ADMIN MANAGEMENT FUNCTIONS ###########################

Core.BaseInstallation::requestUpdate () {
	local ACTION=${1:-"update"}
	log <<< ""

	# First: Check, if the user can update the base installation, otherwise switch user

	if [[ $USER != $ADMIN ]]; then
		warning <<-EOF # TODO: update text similar to Core.Setup::beginSetup
			Only the admin **$ADMIN** can $ACTION the base installation.
			Please switch to the account of **$ADMIN** now! (or CTRL-C to cancel)
		EOF

		sudo -iu $ADMIN \
			MSM_REMOTE=1 "$THIS_SCRIPT" "$ACTION"
		return
	fi

	# Now, check if an update is available at all

	if [[ ! $MSM_DO_UPDATE && $ACTION == "update" ]]; then
		out <<< "Checking for updates ..."

		App::isUpToDate && {
			info <<< "The base installation is already up to date."
			return
		}
		(( $? > 1 )) && return

		info <<< "An update for the base installation is available."
		out  <<< "Do you wish to perform the update now?"
		promptY || return
	fi

	# If not in a TMUX environment, switch into one to perform the update.
	# This way, an SSH disconnection or closing the terminal won't interrupt it.

	if ! [[ $TMUX && $MSM_DO_UPDATE == 1 ]]; then
		out  <<< "Switching into TMUX for performing the update ..."

		local SOCKET="$TMPDIR/update.tmux-socket"

		tmux -S "$SOCKET" has-session > /dev/null 2>&1 && {
			tmux -S "$SOCKET" attach
			return
		}

		delete-tmux

		local OLD_LOGFILE="$MSM_LOGFILE"
		local UPDATE_LOGFILE="$LOGDIR/$(timestamp)-$ACTION.log"
		export MSM_LOGFILE="$UPDATE_LOGFILE"
		export MSM_DO_UPDATE=1

		# Execute Update within tmux
		tmux -S "$SOCKET" -f "$THIS_DIR/tmux.conf" new-session "$THIS_SCRIPT" "$ACTION"

		local errno=$?

		unset MSM_DO_UPDATE MSM_LOGFILE
		MSM_LOGFILE="$OLD_LOGFILE"

		if (( $errno )); then
			error <<-EOF
				Update failed. See the log file **$UPDATE_LOGFILE**
				for more information.
			EOF
		else
			success <<< "Your $APP server was ${ACTION}d successfully!"
		fi

		return $errno
	fi


	# Perform update
	App::performUpdate $ACTION
}