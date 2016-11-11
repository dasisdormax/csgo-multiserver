#! /bin/bash

# (C) 2016 Maximilian Wende <maximilian.wende@gmail.com>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0




Core.BaseInstallation::registerCommands () {
	simpleCommand "Core.BaseInstallation::requestUpdate" update install
	simpleCommand "Core.BaseInstallation::requestRepair" repair validate
	oneArgCommand "Core.BaseInstallation::cloneFrom" clone
}


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


# Clone the base installation from a different machine
# Takes the remote user to copy from in ssh format (user@host)
#
# TODO: test this!!!
Core.BaseInstallation::cloneFrom () {

	[[ $1 ]] || return
	requireConfig && requireAdmin || return

	log <<< ""
	log <<< "Loading $APP server settings from $1 ..."

	# Get remote install dir
	REMOTE_DIR="$(
		unset INSTALL_DIR
		eval "$(ssh $1 MSM_REMOTE=1 APP="$APP" "$THIS_COMMAND" print-config | 
				grep ^INSTALL_DIR= )"
		echo "$INSTALL_DIR"
	)"

	[[ $REMOTE_DIR ]] || error <<-EOF || return
			Could not load the configuration of $1! Please make
			sure that your base installation is set up properly on
			that machine!
		EOF

	# Save host to base installation configuration
	echo "$REMOTE_DIR" > "$INSTALL_DIR/msm.d/cloned-from"

	Core.BaseInstallation::updateFromClone
}


Core.BaseInstallation::updateFromClone () {
	local REMOTE_DIR="$(cat "$INSTALL_DIR/msm.d/cloned-from")"
	# Rsync from the remote install dir into this install dir
	log <<< "Cloning Base Installation (this may take a while) ..."
	if rsync -az "$1:$REMOTE_DIR/" "$INSTALL_DIR"; then
		success <<< "The server files have been cloned successfully."
	else
		error <<< "Error cloning the server files! (rsync exited with code $?)"
	fi
}




####################### UPDATE AND INSTALLATION HANDLING #######################

requireUpdater () {
	App::isUpdaterInstalled || error <<-EOF
		The updater for $APP is not installed!

		Install the updater using **$THIS_COMMAND setup**.
	EOF
}


Core.BaseInstallation::requestRepair () {
	requireConfig && requireAdmin && requireUpdater || return

	ACTION="repair" Core.BaseInstallation::startUpdate
}


Core.BaseInstallation::requestUpdate () {

	requireConfig && requireAdmin && requireUpdater || return

	########## Check if an update is available at all

	log <<< ""
	log <<< "Checking for updates ..."

	Core.BaseInstallation::isUpToDate && {
		info <<< "The base installation is already up to date."
		return
	}

	info <<< "The base installation needs to be updated!"

	ACTION="update" Core.BaseInstallation::startUpdate
}


Core.BaseInstallation::isUpToDate () {
	if [[ -e "$INSTALL_DIR/msm.d/cloned-from" ]]; then
		# get timestamp of msm.d/app over ssh
		local REMOTE_DIR="$(cat "$INSTALL_DIR/msm.d/cloned-from")"
		local REMOTE_HOST="${REMOTE_DIR%%:*}"
		local REMOTE_TIME="$(ssh "$REMOTE_HOST" date -r "$REMOTE_DIR/msm.d/app" +%s)"
		local LOCAL_TIME="$(date -r "$INSTALL_DIR/msm.d/app" +%s)"
		(( LOCAL_TIME > REMOTE_TIME ))
	else
		App::isUpToDate
	fi
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

	if [[ -e "$INSTALL_DIR/msm.d/cloned-from" ]]; then
		Core.BaseInstallation::updateFromClone
	else
		App::performUpdate
	fi
	local errno=$?

	########## Update timestamp on app file, so clients know that files may have changed

	log <<< ""
	log <<< "Finalizing and applying permissions ..."
	rm "$INSTALL_DIR/msm.d/update" 2>/dev/null
	touch "$INSTALL_DIR/msm.d/app"
	Core.BaseInstallation::applyPermissions

	if (( $errno )); then
		error <<-EOF
			${ACTION^} failed. See the log file **$UPDATE_LOGFILE**
			for more information.
		EOF
	else
		success <<< "${ACTION^} of your $APP server completed successfully!"
	fi

	return $errno
)
