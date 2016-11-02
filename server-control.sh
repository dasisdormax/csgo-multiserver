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
	rm "$TMPDIR/server.exit-code" 2>/dev/null
	tmux new-window -n "$APP-server" /bin/bash "$TMPDIR/server-start.sh"
}

echo () {
	builtin echo "[$(date "+%Y/%m/%d %T")]" $*
}

##################################################################################
############################### PROGRAM STARTS HERE ##############################
##################################################################################

# Initialization
. "$THIS_DIR/helpers.sh"
APP=$(cat "$INSTANCE_DIR/msm.d/app")

cat <<-EOF
		                           server-control.sh
		                           =================

	EOF

catinfo <<-EOF
	INFO:  This program will control the **$APP** server and react to events
	       such as server crashes, pending updates and user commands.
EOF

############ STATES ############
# - UPDATING                   #
# - LAUNCHING                  #
# - RUNNING                    #
# - STOPPING FOR UPDATE        #
# - STOPPING                   #
# - STOPPED                    #
################################
STATE="UPDATING"

while [[ $STATE != "STOPPED" ]]; do

	case "$STATE" in

		( UPDATING )
			if [[ -e "$INSTANCE_DIR/msm.d/tmp/stop" ]]; then 
				echo "Received stop signal!"
				STATE="STOPPED"
			else
				if update-check; then
					# Update has finished
					STATE="LAUNCHING"
				else
					echo "Waiting for updates to finish ..."
					inotifywait -qq -t $(( 21600 - TIME_DIFF )) -e close_write,delete_self "$INSTALL_DIR/msm.d/update" "$INSTANCE_DIR/msm.d/tmp"
					continue; fi
				fi
			;;

		( LAUNCHING )
			# TODO: symlink_all_files here
			echo "Launching $APP server ..."
			start-server
			STATE="RUNNING"
			;;

		( RUNNING )
			# Perform ALL the checks
			if [[ -e "$INSTANCE_DIR/msm.d/tmp/stop" ]]; then 
				echo "Received stop signal!"
				STATE="STOPPING"; fi
			
			if ! update-check; then STATE="STOPPING FOR UPDATE"; fi # if an update is pending

			errno="$( cat "$INSTANCE_DIR/msm.d/tmp/server.exit-code" 2>/dev/null )"
			if [[ $errno ]]; then
				echo "Server exited with exit code $errno."
				if (( $errno ))
					then echo "Server crashed. Relaunching ..."; STATE="LAUNCHING"
					else STATE="STOPPED"; fi
				fi

			# Wait for stop/update commands or the server exiting
			# Regularly check if something has happened
			if [[ $STATE == "RUNNING" ]]; then
				inotifywait -qq -t 300 -e close_write,delete_self "$INSTALL_DIR/msm.d" "$INSTANCE_DIR/msm.d/tmp"
				continue; fi
			;;

		( "STOPPING FOR UPDATE" )
			if [[ $(tmux list-windows) =~ $APP-server ]]; then # server still running
				# TODO: try it the soft way

				# Do it the hard way
				tmux kill-window -t ":$APP-server"
				continue
			else STATE="UPDATING"; fi
			;;

		( STOPPING )
			if [[ $(tmux list-windows) =~ $APP-server ]]; then # server still running
				# TODO: try it the soft way

				# Do it the hard way
				tmux kill-window -t ":$APP-server"
				continue
			else STATE="STOPPED"; fi
			;;

		esac

	builtin echo
	echo "==> $STATE"


	done
