#! /bin/bash

# (C) 2016 Maximilian Wende <maximilian.wende@gmail.com>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0




################################# STATUS QUERY #################################

# Returns true, if the server wrapper is running
#               (the server may be running or updating)
Core.Server::isRunning () {
	[[ -e "$SOCKET" ]] && tmux -S "$SOCKET" has-session
} >/dev/null 2>&1


# Returns true, if the server wrapper is running and waits for an update to finish
Core.Server::isUpdating () {
	Core.Server::isRunning && [[ ! $(tmux -S "$SOCKET" list-windows) =~ $APP-server ]]
}




########################### SERVER CONTROL FUNCTIONS ###########################

Core.Server::requestStart () {

	log <<< ""
	requireRunnableInstance || return

	Core.Server::isRunning && info <<-EOF && return
			**$INSTANCE_TEXT** is already running! You can enter your
			server's console using **$THIS_COMMAND @$INSTANCE console**.
		EOF

	out <<< "Starting **$INSTANCE_TEXT** ..."

	# Symlink new files
	[[ $INSTALL_DIR/msm.d/app -nt $INSTANCE_DIR/msm.d/app ]] && (
		info <<-EOF
			The base installation has been updated since the last launch.
			Synchronizing ...
		EOF
		cd "$INSTANCE_DIR"
		Core.Instance::symlinkFiles
		App::finalizeInstance
		App::applyInstancePermissions
		touch "msm.d/app"
	)

	# Load instance configuration
	App::calculateLaunchArgs || return

	info <<< "The launch command is:"
	fmt -w67 <<< "$SERVER_EXEC ${LAUNCH_ARGS[@]}" | indent | indent | catinfo

	cat > "$TMPDIR/server-start.sh"   <<-EOF
			#! /bin/bash
			$(declare -f timestamp)
			unbuffer -p "$INSTANCE_DIR/$SERVER_EXEC" ${LAUNCH_ARGS[@]} | tee "$LOGDIR/\$(timestamp)-server.log"
			echo \$? > "$TMPDIR/server.exit-code"
		EOF

	cat > "$TMPDIR/server-control.sh" <<-EOF
			#! /bin/bash
			$(declare -f timestamp)
			. "$HOME/$MSM_CFG"
			THIS_DIR="$THIS_DIR"
			INSTANCE_DIR="$INSTANCE_DIR"
			INSTALL_DIR="$INSTALL_DIR"
			TMPDIR="$TMPDIR"
			MSM_LOGFILE="$INSTANCE_DIR/msm.d/log/\$(timestamp)-controller.log"
			echo "\$LOGFILE" > "$TMPDIR/server-control.logfile"
			. "\$THIS_DIR/server-control.sh"
		EOF

	# LAUNCH! (in tmux)

	tmux -f "$THIS_DIR/cfg/tmux.conf" -S "$SOCKET" new-session -n "server-control" -s "$APP@$INSTANCE" /bin/bash "$INSTANCE_DIR/msm.d/tmp/server-control.sh" \; detach

	success <<-EOF
		**$INSTANCE_TEXT** started successfully!

		Use '$THIS_COMMAND @$INSTANCE console** to enter the game's console.
	EOF
}


Core.Server::requestStop () {

	log <<< ""

	if Core.Server::isRunning; then
		out <<< "Stopping $INSTANCE_TEXT ..."

		touch "$TMPDIR/stop"
		# Give 45 seconds to stop 'softly'
		inotifywait -qq -t 45 -e close_write "$(cat "$TMPDIR/server-control.logfile")"

		rm "$TMPDIR/stop"

		# If it hasn't stopped yet, the server will be stopped the hard way now
		kill-tmux

		success <<< "Stopped **$INSTANCE_TEXT**."
	else
		info <<< "**$INSTANCE_TEXT** is already stopped."
	fi
}


Core.Server::printStatus () {

	log <<< ""
	requireRunnableInstance || return

	if ! Core.Server::isRunning; then
		info <<< "**$INSTANCE_TEXT** is STOPPED."
		return
	fi

	if Core.Server::isUpdating; then
		info <<< "**$INSTANCE_TEXT** is currently UPDATING."
		return
	fi

	info <<< "**$INSTANCE_TEXT** is RUNNING."
}

# Switch to the game's console running in tmux
Core.Server::attachToConsole () {

	log <<< ""
	requireRunnableInstance || return

	out <<< "Connecting to $INSTANCE_TEXT ..."

	if    Core.Server::isUpdating; then
		tmux -S "$SOCKET" attach
	elif  Core.Server::isRunning;  then
		tmux -S "$SOCKET" attach -t ":$APPNAME-server"
	else
		error <<-EOF
			**$INSTANCE_TEXT** is not running! Start your server using
			**$THIS_COMMAND @$INSTANCE start** and try again.
		EOF
	fi
}




