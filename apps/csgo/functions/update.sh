#! /bin/bash

# (C) 2016 Maximilian Wende <maximilian.wende@gmail.com>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0




# Check, if an update to the CS:GO Base Installation is available
# returns 0, if the most current version is installed
#         1, if an update is available
#         2, if the game is not installed yet
#         9, if checking for the update failed
App::isUpToDate () {

	# variables
	local APPMANIFEST="$INSTALL_DIR/steamapps/appmanifest_740.acf"

	# If game is not installed yet, skip checking
	[[ -e $APPMANIFEST ]] || return 2

	# Clear cache
	rm ~/Steam/appcache/appinfo.vdf 2>/dev/null

	local STEAMCMD_SCRIPT="$TMPDIR/steamcmd-script"
	local STEAMCMD_OUT="$TMPDIR/steamcmd-out"
	cat <<-EOF > "$STEAMCMD_SCRIPT"
		login anonymous
		app_info_update 1
		app_info_print 740
		quit
	EOF

	rm "$STEAMCMD_OUT" 2>/dev/null
	# Get current build id through SteamCMD
	unbuffer "$STEAMCMD_DIR/steamcmd.sh" +runscript "$STEAMCMD_SCRIPT" | MSM_LOGFILE="$STEAMCMD_OUT" log >&3

	local oldbuildid=$(cat "$APPMANIFEST" | grep "buildid" | awk '{ print $2 }')
	local newbuildid=$(
			cat "$STEAMCMD_OUT" |
			sed -n "/^\"740\"$/        ,/^}/     p" |
			sed -n '/^\t\t"branches"/,/^\t\t}/   p' |
			sed -n '/^\t\t\t"public"/,/^\t\t\t}/ p' |
			grep "buildid" | awk '{ print $2 }'
		)

	(( $? == 0 )) || error <<< "Could not search for updates!" || return 9

	debug <<< "Installed build is $oldbuildid, most recent build is $newbuildid."

	[[ $oldbuildid == $newbuildid ]]
}


# Actually perform a requested update
# Takes the action (either update or validate) as parameter
App::performUpdate () {

	# Prepare SteamCMD script
	local STEAMCMD_SCRIPT="$TMPDIR/steamcmd-script"
	cat <<-EOF > "$STEAMCMD_SCRIPT"
		login anonymous
		force_install_dir "$INSTALL_DIR"
		app_update 740 $( [[ $ACTION == validate ]] && echo "validate" )
		quit
	EOF

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
			unbuffer "$STEAMCMD_DIR/steamcmd.sh" +runscript "$STEAMCMD_SCRIPT"
			echo; # An additional newline, as SteamCMD is weird
		} | log

		egrep "Success! App '740'.*(fully installed|up to date)" \
		      "$MSM_LOGFILE" > /dev/null                   && local code=0

	done

	# App::applyInstancePermissions

	return $code
}