#! /bin/bash

# (C) 2016 Maximilian Wende <maximilian.wende@gmail.com>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0




########################### CREATING A BASE INSTALLATION ##########################

Core.BaseInstallation::isExisting () {
	INSTANCE_DIR=$INSTALL_DIR Core.Instance::isBaseInstallation && \
		info <<< "An existing base installation was found in $(bold "$INSTALL_DIR")"
}


# creates a base installation in the directory specified by $INSTALL_DIR
Core.BaseInstallation::create () (

	Core.BaseInstallation::isExisting && return

	umask o+rx # make sure that other users can 'fork' this base installation
	INSTANCE_DIR="$INSTALL_DIR"

	Core.Instance::isValidDir && {
		warning <<-EOF
			The directory $(bold "$INSTALL_DIR") is non-empty, creating a base
			installation here may cause $(bold "LOSS OF DATA")!

			Please backup all important files before proceeding!

		EOF
		sleep 2
		promptN || return
	}

	# Create base installation directory
	mkdir -p "$INSTALL_DIR" && [[ -w "$INSTALL_DIR" ]] || {
		fatal <<< "No permission to create or write the directory $(bold "$INSTALL_DIR")!"
		return
	}

	# Make existing files readable for other users
	chmod -R +rX "$INSTALL_DIR"

	# Delete old configuration
	rm -rf --one-file-system "$INSTALL_DIR/msm.d" 2>/dev/null

	# Create new configuration
	mkdir "$INSTALL_DIR/msm.d"
	echo "$APPID" > "$INSTALL_DIR/msm.d/appid"
	echo "$APP"   > "$INSTALL_DIR/msm.d/appname"
	touch "$INSTALL_DIR/msm.d/is-admin" # Mark as base installation

)


steamcmd-scripts () {
	################# TODO: Include these in a better way #################

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
}




########################### ADMIN MANAGEMENT FUNCTIONS ###########################

Core.BaseInstallation::requestUpdate () {
	local ACTION="update"
	if [[ $1 == "validate" ]]; then local ACTION="validate"; fi

	# First: Check, if the user can update the base installation, otherwise switch user
	if [[ $USER != $ADMIN ]]; then
		warning <<-EOF # TODO: update text similar to Core.Setup::beginSetup
			Only the admin $(bold $ADMIN) can $ACTION the base installation.
			Please switch to the account of $(bold $ADMIN) now! (or CTRL-C to cancel)
		EOF

		sudo -i -u $ADMIN "$THIS_SCRIPT" "$ACTION" \
			|| error <<< "Installation/update as $(bold $ADMIN) failed!"

		return
	fi

	# Now, check if an update is available at all
	local APPMANIFEST="$INSTALL_DIR/steamapps/appmanifest_$APPID.acf"
	if [[ ! $MSM_DO_UPDATE && -e $APPMANIFEST && $ACTION == "update" ]]; then
		echo "Checking for updates ..."
		rm ~/Steam/appcache/appinfo.vdf 2>/dev/null # Clear cache
		local buildid=$(
			"$STEAMCMD_DIR/steamcmd.sh" +runscript "$STEAMCMD_DIR/update-check" |
				sed -n '/^"740"$/        ,/^}/       p' |
				sed -n '/^\t\t"branches"/,/^\t\t}/   p' |
				sed -n '/^\t\t\t"public"/,/^\t\t\t}/ p' |
				grep "buildid" | awk '{ print $2 }'
			)

		(( $? == 0 )) || error <<< "Searching for updates failed!" || return

		[[ $(cat "$APPMANIFEST" | grep "buildid" | awk '{ print $2 }') == $buildid ]] && {
			info <<< "The base installation is already up to date."
			return
		}

		info <<< "An update for the base installation is available."
		echo
	fi

	# If not in a TMUX environment, switch into one to perform the update.
	# This way, an SSH disconnection or closing the terminal won't interrupt it.
	if ! [[ $TMUX && $MSM_DO_UPDATE == 1 ]]; then
		echo "Switching into TMUX for performing the update ..."

		TMPDIR="$INSTALL_DIR/msm.d/tmp"
		mkdir -p "$TMPDIR"
		local SOCKET="$TMPDIR/update.tmux-socket"

		if ( tmux -S "$SOCKET" has-session > /dev/null 2>&1 ); then 
			tmux -S "$SOCKET" attach
			echo
			return 0
		fi

		delete-tmux

		export MSM_DO_UPDATE=1
		tmux -S "$SOCKET" -f "$THIS_DIR/tmux.conf" new-session "$THIS_SCRIPT" "$ACTION"
		local errno=$?
		unset MSM_DO_UPDATE
		echo

		return $errno; fi

	Core.BaseInstallation::performUpdate $ACTION
}

# Actually perform a requested update
# Takes the action (either update or validate) as parameter
Core.BaseInstallation::performUpdate () {
	# Tell running instances that the update is starting soon
	local UPDATE_TIME=$(( $(date +%s) + $UPDATE_WAITTIME ))
	echo $UPDATE_TIME > "$INSTALL_DIR/msm.d/update" # obtain 'lock' in the future
	trap "" SIGINT
	printf "Waiting $UPDATE_WAITTIME seconds for running instances to stop ... "
	while (( $(date +%s) < $UPDATE_TIME )); do sleep 1; done
	trap SIGINT
	echo; echo

	local LOGFILE="$STEAMCMD_DIR/$ACTION.log"
	echo > "$LOGFILE"
	echo "Performing update/installation NOW. Log File: $(bold "$LOGFILE")"
	echo

	tries=5
	try=0
	unset SUCCESS
	until [[ $SUCCESS ]] || (( ++try > tries )); do
		tee -a "$LOGFILE" <<-EOF | catinfo
			####################################################
			# $(printf "[%2d/%2d] %40s" $try $tries "$(date)") #
			# $(printf "%-48s" "Trying to $ACTION the game using SteamCMD ...") #
			####################################################

			EOF
		$(which unbuffer) "$STEAMCMD_DIR/steamcmd.sh" +runscript "$STEAMCMD_DIR/$ACTION" | tee -a "$LOGFILE"
		echo >> "$LOGFILE" # an extra newline in the file because of the weird escape sequences that steam uses
		echo | tee -a "$LOGFILE"

		egrep "Success! App '$APPID'.*(fully installed|up to date)" "$LOGFILE" > /dev/null && local SUCCESS=1

		done

	fix-permissions

	# Update timestamp on appid file, so clients know that files may have changed
	rm "$INSTALL_DIR/msm.d/update" 2>/dev/null
	touch "$INSTALL_DIR/msm.d/appid"

	unset try tries
	if [[ $SUCCESS ]]; then
		catinfo <<< "$(bold INFO:)  Update completed successfully!"
		echo
		return 0
	else catwarn <<-EOF
		$(bold WARN:)  Update failed! For more information, see the log file"
		       at $(bold "$LOGFILE")."

		EOF
		return 1; fi
}