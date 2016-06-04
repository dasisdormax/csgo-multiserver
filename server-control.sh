#! /bin/bash

# (C) 2016 Maximilian Wende <maximilian.wende@gmail.com>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0




################################ HELPER FUNCTIONS ################################
update-check () {
	UPDATE_TIME=$(cat "$INSTALL_DIR/msm.d/update" 2>/dev/null)
	if [[ ! UPDATE_TIME ]]; then return 0; fi
	TIME_DIFF=$(( $(date +%s) - UPDATE_TIME ))
	
	# If an update takes longer than 6 hours, assume that it has failed
	if (( TIME_DIFF > 21600 )); then return 0; fi

	# Update is planned, stop the server
	if (( TIME_DIFF < -15 )); then return 1; fi

	# Update in progress
	return 2;
}

start-server () {
	rm "$INSTANCE_DIR/msm.d/tmp/server.exit-code" 2>/dev/null
	tmux new-window -n "$APPNAME-server" /bin/bash "$INSTANCE_DIR/msm.d/tmp/server-start.sh"
}

alias echo='echo "[$(date "+%Y/%m/%d %T")]"'

##################################################################################
############################### PROGRAM STARTS HERE ##############################
##################################################################################

# Initialization
. "$THIS_DIR/helpers.sh"
APPNAME=$(cat "$INSTANCE_DIR/msm.d/appname")
cat <<-EOF
		                           server-control.sh
		                           =================

	EOF

catinfo <<-EOF
		$(bold INFO:)  This program will control the $(bold $APPNAME) server and react to events
		       such as server crashes, pending updates and user commands.

	EOF

tmux rename-window server-control

# Start the action

############ STATES ############
# - Updating
# - Launching
# - Running
# - StoppingForUpdate
# - Stopping
# - Stopped
################################
STATE="Updating"

while [[ $STATE != "Stopped" ]]; do


	case "$STATE" in

		( Updating )
			if update-check; then
				# Update has finished
				STATE="Launching"
			else
				echo "Waiting for updates to finish ..."
				inotifywait -t $(( 21600 - TIME_DIFF )) "$INSTALL_DIR/msm.d/update"
				fi
			;;

		( Launching )
			echo "Launching $APPNAME server ..."
			start-server
			STATE="Running"
			;;

		( Running )
			sleep 5 # For now
			;;

		( StoppingForUpdate )
			;;

		( Stopping )
			;;

		esac


	done
