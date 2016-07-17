#! /bin/bash

# (C) 2016 Maximilian Wende <maximilian.wende@gmail.com>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0




########################### ADMIN MANAGEMENT FUNCTIONS ###########################

update () {
	local ACTION="update"
	if [[ $1 == "validate" ]]; then local ACTION="validate"; fi
	if [[ $USER != $ADMIN ]]; then
		catwarn <<-EOF
			Only the admin $(bold $ADMIN) can $ACTION the base installation.
			Please switch to the account of $(bold $ADMIN) now! (or CTRL-D to cancel)
			EOF
		sudo -i -u $ADMIN "$THIS_SCRIPT" "$ACTION"
		if (( $? )); then caterr <<-EOF
				$(bold ERROR:) Installation/update as $(bold $ADMIN) failed!

				EOF
			return 1; fi

		return 0; fi

	# First, check if an update is available at all
	local APPMANIFEST="$INSTALL_DIR/steamapps/appmanifest_$APPID.acf"
	if [[ ! $PERFORM_UPDATE && -e $APPMANIFEST && $ACTION == "update" ]]; then
		echo "Checking for updates ..."
		rm ~/Steam/appcache/appinfo.vdf 2>/dev/null # Clear cache
		local buildid=$(
			"$STEAMCMD_DIR/steamcmd.sh" +runscript "$STEAMCMD_DIR/update-check" |
				sed -n '/^"740"$/        ,/^}/       p' |
				sed -n '/^\t\t"branches"/,/^\t\t}/   p' |
				sed -n '/^\t\t\t"public"/,/^\t\t\t}/ p' |
				grep "buildid" | awk '{ print $2 }'
			)

		if (( $? )); then caterr <<-EOF
				$(bold ERROR:) Searching for updates failed!

				EOF
			return 1; fi
		if [[ $(cat "$APPMANIFEST" | grep "buildid" | awk '{ print $2 }' 2>/dev/null) == $buildid ]]; then
			# No update is necessary
			catinfo <<< "$(bold INFO:)  The base installation is already up to date."
			echo
			return 0; fi

		catinfo <<< "$(bold INFO:)  An update for the base installation is available."
		echo
		fi

	# Perform the actual update within a tmux environment, so closing the terminal or
	# an interruption of an SSH session does not interrupt the update
	if ! [[ $TMUX && $PERFORM_UPDATE ]]; then
		echo "Switching into TMUX for performing the update ..."

		TMPDIR="$INSTALL_DIR/msm.d/tmp"
		mkdir -p "$TMPDIR"
		local SOCKET="$TMPDIR/update.tmux-socket"

		if ( tmux -S "$SOCKET" has-session > /dev/null 2>&1 ); then 
			tmux -S "$SOCKET" attach
			echo; return 0; fi

		delete-tmux

		export PERFORM_UPDATE=1
		tmux -S "$SOCKET" -f "$THIS_DIR/tmux.conf" new-session "$THIS_SCRIPT" "$ACTION"
		local errno=$?
		unset PERFORM_UPDATE

		echo; return $errno; fi

	local UPDATE_TIME=$(( $(date +%s) + $UPDATE_WAITTIME ))
	echo $UPDATE_TIME > "$INSTALL_DIR/msm.d/update"
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