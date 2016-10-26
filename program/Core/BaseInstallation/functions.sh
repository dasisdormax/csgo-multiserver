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
	echo "$APPID" > "$INSTALL_DIR/msm.d/appid"
	echo "$APP"   > "$INSTALL_DIR/msm.d/appname"
	touch "$INSTALL_DIR/msm.d/is-admin" # Mark as base installation

	# Create temporary and logging directories
	mkdir "$INSTALL_DIR/msm.d/tmp"
	mkdir "$INSTALL_DIR/msm.d/log"
)




########################### ADMIN MANAGEMENT FUNCTIONS ###########################

Core.BaseInstallation::requestUpdate () {
	local ACTION=${1:-"update"}

	# First: Check, if the user can update the base installation, otherwise switch user
	if [[ $USER != $ADMIN ]]; then
		warning <<-EOF # TODO: update text similar to Core.Setup::beginSetup
			Only the admin **$ADMIN** can $ACTION the base installation.
			Please switch to the account of **$ADMIN** now! (or CTRL-C to cancel)
		EOF

		sudo -i -u $ADMIN "$THIS_SCRIPT" "$ACTION" \
			|| error <<< "Installation/update as **$ADMIN** failed!"

		return
	fi

	# Now, check if an update is available at all
	local APPMANIFEST="$INSTALL_DIR/steamapps/appmanifest_$APPID.acf"
	local STEAMCMD_SCRIPT="$INSTALL_DIR/msm.d/tmp/steamcmd-script"
	if [[ ! $MSM_DO_UPDATE && -e $APPMANIFEST && $ACTION == "update" ]]; then
		echo "Checking for updates ..."
		rm ~/Steam/appcache/appinfo.vdf 2>/dev/null # Clear cache

		# Query current version through SteamCMD
		cat <<-EOF > "$STEAMCMD_SCRIPT"
			login anonymous
			app_info_update 1
			app_info_print $APPID
			quit
		EOF
		local buildid=$(
			"$STEAMCMD_DIR/steamcmd.sh" +runscript "$STEAMCMD_DIR/update-check" |
				sed -n "/^\"$APPID\"$/        ,/^}/  p" |
				sed -n '/^\t\t"branches"/,/^\t\t}/   p' |
				sed -n '/^\t\t\t"public"/,/^\t\t\t}/ p' |
				grep "buildid" | awk '{ print $2 }'
			)

		(( $? == 0 )) || error <<< "Searching for updates failed!" || return

		[[ $(cat "$APPMANIFEST" | grep "buildid" | awk '{ print $2 }') == $buildid ]] && {
			info <<< "The base installation is already up to date."
			echo; return
		}

		info <<< "An update for the base installation is available."
		echo
		echo "Do you wish to perform the update now?"
		promptY || return
	fi

	# If not in a TMUX environment, switch into one to perform the update.
	# This way, an SSH disconnection or closing the terminal won't interrupt it.
	if ! [[ $TMUX && $MSM_DO_UPDATE == 1 ]]; then
		echo "Switching into TMUX for performing the update ..."

		TMPDIR="$INSTALL_DIR/msm.d/tmp"
		local SOCKET="$TMPDIR/update.tmux-socket"

		tmux -S "$SOCKET" has-session > /dev/null 2>&1 && {
			tmux -S "$SOCKET" attach
			return
		}

		delete-tmux

		export MSM_DO_UPDATE=1
		export MSM_UPDATE_LOGFILE="$INSTALL_DIR/msm.d/log/$(timestamp)-$ACTION.log"

		# Execute Update within tmux
		tmux -S "$SOCKET" -f "$THIS_DIR/tmux.conf" new-session "$THIS_SCRIPT" "$ACTION"

		local errno=$?
		if (( $errno )); then
			error <<-EOF
				Update failed. See the log file $(bold "$MSM_UPDATE_LOGFILE")
				for more information.

			EOF
		else
			success <<-EOF
				Your $APP server was ${ACTION}d successfully!

			EOF
		fi

		unset MSM_DO_UPDATE MSM_UPDATE_LOGFILE
		return $errno
	fi


	# Perform update
	Core.BaseInstallation::performUpdate $ACTION
}

# Actually perform a requested update
# Takes the action (either update or validate) as parameter
Core.BaseInstallation::performUpdate () (

	# Tell running instances that the update is starting soon
	umask o+rx
	local UPDATE_TIME=$(( $(date +%s) + $UPDATE_WAITTIME ))
	echo $UPDATE_TIME > "$INSTALL_DIR/msm.d/update"

	# Wait (meanwhile, prevent exiting on Ctrl-C)
	# TODO: Allow the user to cancel the update
	trap "" SIGINT
	printf "Waiting $UPDATE_WAITTIME seconds for running instances to stop ... "
	while (( $(date +%s) < $UPDATE_TIME )); do sleep 1; done
	trap SIGINT
	echo; echo

	cat <<-EOF > "$STEAMCMD_SCRIPT"
		login anonymous
		force_install_dir "$INSTALL_DIR"
		app_update $APPID $( [[ $ACTION == validate ]] && echo "validate" )
		quit
	EOF

	# Done waiting and preparing, the update can be started now

	echo > "$MSM_UPDATE_LOGFILE"
	echo "Performing update/installation NOW. Log File: $(bold "$MSM_UPDATE_LOGFILE")"
	echo

	local tries=5
	local try=0
	unset SUCCESS
	until [[ $SUCCESS ]] || (( ++try > tries )); do
		tee -a "$LOGFILE" <<-EOF | catinfo
			####################################################
			# $(printf "[%2d/%2d] %40s" $try $tries "$(date)") #
			# $(printf "%-48s" "Trying to $ACTION the game using SteamCMD ...") #
			####################################################

		EOF
		$(which unbuffer) "$STEAMCMD_DIR/steamcmd.sh" +runscript "$STEAMCMD_SCRIPT" | tee -a "$LOGFILE"
		echo >> "$LOGFILE" # an extra newline in the file because of the weird escape sequences that steam uses
		echo | tee -a "$LOGFILE"

		egrep "Success! App '$APPID'.*(fully installed|up to date)" "$LOGFILE" > /dev/null && local SUCCESS=1

	done

	# App::applyInstancePermissions

	# Update timestamp on appid file, so clients know that files may have changed
	rm "$INSTALL_DIR/msm.d/update" 2>/dev/null
	touch "$INSTALL_DIR/msm.d/appid"

	return $SUCCESS
)