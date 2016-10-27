#! /bin/bash

# (C) 2016 Maximilian Wende <maximilian.wende@gmail.com>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0




# Check, if an update to the CS:GO Base Installation is available
# returns 0, if the most current version is installed
#         1, if an update is available or the game is not installed yed
#         9, if checking for the update failed
App::isUpToDate () {

	# variables
	local APPMANIFEST="$INSTALL_DIR/steamapps/appmanifest_740.acf"

	# If game is not installed yet, skip checking
	[[ -e $APPMANIFEST ]] || return

	# Clear cache
	rm ~/Steam/appcache/appinfo.vdf 2>/dev/null

	local STEAMCMD_SCRIPT="$TMPDIR/steamcmd-script"
	cat <<-EOF > "$STEAMCMD_SCRIPT"
		login anonymous
		app_info_update 1
		app_info_print 740
		quit
	EOF

	# Get current build id through SteamCMD
	local buildid=$(
		"$STEAMCMD_DIR/steamcmd.sh" +runscript "$STEAMCMD_DIR/update-check" |
			sed -n "/^\"740\"$/        ,/^}/     p" |
			sed -n '/^\t\t"branches"/,/^\t\t}/   p' |
			sed -n '/^\t\t\t"public"/,/^\t\t\t}/ p' |
			grep "buildid" | awk '{ print $2 }'
		)

	(( $? == 0 )) || error <<< "Searching for updates failed!" || return 9

	[[ $(cat "$APPMANIFEST" | grep "buildid" | awk '{ print $2 }') == $buildid ]]
}


# Actually perform a requested update
# Takes the action (either update or validate) as parameter
App::performUpdate () (

	# Tell running instances that the update is starting soon
	umask o+rx
	local UPDATE_TIME=$(( $(date +%s) + $UPDATE_WAITTIME ))
	echo $UPDATE_TIME > "$INSTALL_DIR/msm.d/update"

	# Wait (meanwhile, prevent exiting on Ctrl-C)
	# TODO: Allow the user to cancel the update
	trap "" SIGINT
	log <<< ""
	log <<< "Waiting $UPDATE_WAITTIME seconds for running instances to stop ..."
	while (( $(date +%s) < $UPDATE_TIME )); do sleep 1; done
	trap SIGINT

	local STEAMCMD_SCRIPT="$TMPDIR/steamcmd-script"
	cat <<-EOF > "$STEAMCMD_SCRIPT"
		login anonymous
		force_install_dir "$INSTALL_DIR"
		app_update $APPID $( [[ $ACTION == validate ]] && echo "validate" )
		quit
	EOF

	# Done waiting and preparing, the update can be started now

	log <<< ""
	log <<< "Performing update/installation NOW."

	local tries=5
	local try=0
	local code=1
	while (( $code && ++try <= tries )); do
		log <<-EOF | catinfo

			####################################################
			# $(printf "[%2d/%2d] %40s" $try $tries "$(date)") #
			# $(printf "%-48s" "Trying to $ACTION the game using SteamCMD ...") #
			####################################################

		EOF

		{
			$(which unbuffer) "$STEAMCMD_DIR/steamcmd.sh" +runscript "$STEAMCMD_SCRIPT"
			echo; # An additional newline, as SteamCMD is weird
		} | log

		egrep "Success! App '$APPID'.*(fully installed|up to date)" \
		      "$MSM_LOGFILE" > /dev/null                   && local code=0

	done

	# App::applyInstancePermissions

	# Update timestamp on appid file, so clients know that files may have changed
	rm "$INSTALL_DIR/msm.d/update" 2>/dev/null
	touch "$INSTALL_DIR/msm.d/appid"

	return $code
)