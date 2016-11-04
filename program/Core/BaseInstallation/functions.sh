#! /bin/bash

# (C) 2016 Maximilian Wende <maximilian.wende@gmail.com>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0




Core.BaseInstallation::applyPermissions() {
	App::applyInstancePermissions 2>/dev/null

	chmod -R a+rX "$INSTALL_DIR"

	chmod -R o-rx "$INSTALL_DIR/msm.d/tmp"
	chmod -R o-rx "$INSTALL_DIR/msm.d/log"
}




########################### CREATING A BASE INSTALLATION ##########################

Core.BaseInstallation::isExisting () {
	INSTANCE_DIR=$INSTALL_DIR Core.Instance::isBaseInstallation
}


# creates a base installation in the directory specified by $INSTALL_DIR
Core.BaseInstallation::create () (

	Core.BaseInstallation::isExisting && return

	umask o+rx # make sure that other users can 'fork' this base installation

	INSTANCE_DIR="$INSTALL_DIR" Core.Instance::isValidDir || {
		warning <<-EOF
			The directory **$INSTALL_DIR** is non-empty, creating a base
			installation here may cause data to be **LOST or LEAKED**!

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
	mkdir -m o-rwx "$TMPDIR"
	mkdir -m o-rwx "$LOGDIR"
)




####################### UPDATE AND INSTALLATION HANDLING #######################

requireUpdater () {
	App::isUpdaterInstalled || error <<-EOF
		The updater for $APP is not installed!

		Install the updater using **$THIS_COMMAND setup**.
	EOF
}


Core.BaseInstallation::requestUpdate () {

	requireConfig || return

	local ACTION=${1:-"update"}

	########## First: Switch user to base installation admin, if necessary

	if [[ $USER != $ADMIN ]]; then
		log <<< ""
		warning <<-EOF # TODO: update text similar to Core.Setup::beginSetup
			The user **$ADMIN** is controlling your base installation exclusively.
			You may, though, switch users to perform the update on their account.

			You will have to confirm this action with your sudo password. (CTRL-C to cancel)

		EOF

		sudo -iu $ADMIN \
			MSM_REMOTE=1 "$THIS_COMMAND" "$ACTION"
		return
	fi

	########## Now, check if an update is available at all

	requireUpdater || return

	if [[ ! $MSM_DO_UPDATE && $ACTION == "update" ]]; then
		log <<< ""
		log <<< "Checking for updates ..."

		App::isUpToDate && {
			info <<< "The base installation is already up to date."
			return
		}
		local code=$?
		if (( code  > 2 )); then return 1; fi
		#  if code == 2, the game server is not installed yet. Asking the user
		#                if they wish to update is unnecessary
		if (( code == 1 )); then
			info <<< "An update for the base installation is available."
			sleep 5
		fi
	fi

	########## If not in a TMUX environment, switch into one to perform the update.
	# This way, an SSH disconnection or closing the terminal won't interrupt it.

	if ! [[ $TMUX && $MSM_DO_UPDATE == 1 ]]; then
		local UPDATE_LOGFILE="$LOGDIR/$(timestamp)-$ACTION.log"

		out <<-EOF

			Switching into a TMUX environment to install or update the
			base installation ...

			For more status information, see the log file
			**$UPDATE_LOGFILE**.
		EOF

		local SOCKET="$TMPDIR/update.tmux-socket"

		tmux -S "$SOCKET" has-session > /dev/null 2>&1 && {
			tmux -S "$SOCKET" attach
			return
		}

		kill-tmux

		local OLD_LOGFILE="$MSM_LOGFILE"
		export MSM_LOGFILE="$UPDATE_LOGFILE"
		export MSM_DO_UPDATE=1

		# Execute Update within tmux
		tmux -S "$SOCKET" -f "$THIS_DIR/cfg/tmux.conf" new-session "$THIS_SCRIPT" "$ACTION"

		unset MSM_DO_UPDATE MSM_LOGFILE
		MSM_LOGFILE="$OLD_LOGFILE"

		return
	fi

	########## Start the actual update procedure

	Core.BaseInstallation::startUpdate $ACTION
}


Core.BaseInstallation::startUpdate () (

	########## Tell running instances that the update is starting soon

	umask o+rx
	local UPDATE_TIME=$(( $(date +%s) + $UPDATE_WAITTIME ))
	echo $UPDATE_TIME > "$INSTALL_DIR/msm.d/update"

	########## Wait (meanwhile, prevent exiting on Ctrl-C)
	# TODO: Allow the user to cancel the update

	trap "" SIGINT
	log <<< ""
	log <<< "Waiting $UPDATE_WAITTIME seconds for running instances to stop ..."
	while (( $(date +%s) < $UPDATE_TIME )); do sleep 1; done
	trap SIGINT

	########## Done waiting, perform the update now.

	log <<< ""
	log <<< "Performing update/installation NOW."

	App::performUpdate
	local errno=$?

	########## Update timestamp on app file, so clients know that files may have changed

	log <<< ""
	log <<< "Finalizing and applying permissions ..."
	rm "$INSTALL_DIR/msm.d/update" 2>/dev/null
	touch "$INSTALL_DIR/msm.d/app"
	Core.BaseInstallation::applyPermissions

	if (( $errno )); then
		error <<-EOF
			Update failed. See the log file **$UPDATE_LOGFILE**
			for more information.
		EOF
	else
		success <<< "Your $APP server was ${ACTION}d successfully!"
	fi

	sleep 5

	return $errno
)
