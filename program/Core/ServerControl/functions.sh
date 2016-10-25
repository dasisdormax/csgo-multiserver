#! /bin/bash

# (C) 2016 Maximilian Wende <maximilian.wende@gmail.com>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0




############################ SERVER CONTROL FUNCTIONS ############################

start () {
	echo "Starting $SERVER_TEXT ..."

	# Check, if instance exists and the user does own it
	if [[ ! -d $INSTANCE_DIR ]]; then caterr <<-EOF
			$(bold ERROR:) Instance directory $(bold "$INSTANCE_DIR") does not exist!
			       Create an instance using '$THIS_COMM @$INSTANCE create-instance'.

			EOF
		return 1; fi

	if [[ ! -w $INSTANCE_DIR ]]; then caterr <<-EOF
			$(bold ERROR:) You do not have full access to $(bold "$INSTANCE_DIR")!
			       Only $(bold $ADMIN) can modify and launch the base installation! Try creating
			       an own instance using '$THIS_COMM @name create-instance' instead.

			EOF
		return 1; fi

	if [[ ! -x $INSTANCE_DIR/$SERVER_EXEC ]]; then caterr <<-EOF
			$(bold ERROR:) Server Executable not found at $(bold "$INSTANCE_DIR/$SERVER_EXEC")!
			       Try repairing the installation using '$THIS_COMM update',
			       '$THIS_COMM repair' or re-create this instance.

			EOF
		return 1; fi

	# Check, if server is already running
	status
	if (( $? < 2 )); then catinfo <<-EOF
			$(bold INFO:)  $SERVER_TEXT is already running!
			       Enter the console using '$THIS_COMM @$INSTANCE console'.

			EOF
		return 0; fi

	# Symlink new files
	if [[ $INSTALL_DIR/msm.d/appid -nt $INSTANCE_DIR/msm.d/appid ]]; then
		echo "Syncing to latest update of base installation ..."
		symlink-all-files
		touch "$INSTANCE_DIR/msm.d/appid"
		fi

	# Load instance configuration
	. $INSTANCE_DIR/msm.d/server.conf
	local errno=$?
	if (( $errno )); then return $errno; fi

	# TODO: Load addon configuration here

	catinfo <<-EOF
			$(bold INFO:)  The launch command is:
			$(bold $SERVER_EXEC) $ARGS
		EOF

	mkdir -p "$INSTANCE_DIR/msm.d/tmp"
	mkdir -p "$INSTANCE_DIR/msm.d/log"

	rm -f "$INSTANCE_DIR/msm.d/tmp/"*

	TIMESTAMP="\$(timestamp)"
	UNBUFFER="$(which unbuffer)"

	cat > "$INSTANCE_DIR/msm.d/tmp/server-start.sh"   <<-EOF
			#! /bin/bash
			${UNBUFFER:+$UNBUFFER -p} "$INSTANCE_DIR/$SERVER_EXEC" $ARGS | tee "$INSTANCE_DIR/msm.d/log/$TIMESTAMP-server.log"
			echo $? > "$INSTANCE_DIR/msm.d/tmp/server.exit-code"
		EOF

	cat > "$INSTANCE_DIR/msm.d/tmp/server-control.sh" <<-EOF
			#! /bin/bash
			. "$HOME/$MSM_CFG"
			THIS_DIR="$THIS_DIR"
			INSTANCE_DIR="$INSTANCE_DIR"
			INSTALL_DIR="$INSTALL_DIR"
			TMPDIR="$INSTANCE_DIR/msm.d/tmp"
			LOGFILE="$INSTANCE_DIR/msm.d/log/$TIMESTAMP-controller.log"
			echo "\$LOGFILE" > "\$TMPDIR/server-control.logfile"
			. "\$THIS_DIR/server-control.sh" | tee "\$LOGFILE"
		EOF

	# LAUNCH! (in tmux)

	tmux -f "$THIS_DIR/tmux.conf" -S "$SOCKET" new-session -n "server-control" -s "$APPNAME@$INSTANCE" /bin/bash "$INSTANCE_DIR/msm.d/tmp/server-control.sh" \; detach

	echo
	echo "$SERVER_TEXT started successfully!"
	echo "To enter the game's console, type '$THIS_COMM @$INSTANCE console'."
	echo
	return 0 # success
}

stop () {
	status
	local errno=$?
	if (( errno == 23 )); then return 1; fi
	if (( errno ==  2 )); then echo "$SERVER_TEXT is already STOPPED!"; echo; return 0; fi

	echo "Stopping $SERVER_TEXT ..."

	touch "$INSTANCE_DIR/msm.d/tmp/stop"

	# Give 60 seconds to stop 'softly'
	inotifywait -qq -t 60 -e close_write "$(cat "$INSTANCE_DIR/msm.d/tmp/server-control.logfile")"

	rm "$INSTANCE_DIR/msm.d/tmp/stop"

	# If it hasn't stopped yet, the server will be stopped the hard way now
	delete-tmux

	echo "$SERVER_TEXT is STOPPED!"; echo
}

# Status (Up/Down and extra info) of the selected server instance
#
# Return Codes:
# true/0   running
#      1   launching/updating
#      2   stopped
#     23   access error
status () {
	if [[ ! -w "$INSTANCE_DIR" ]]; then caterr <<-EOF
			$(bold ERROR:) $SERVER_TEXT (directory: $(bold "$INSTANCE_DIR"))
			       does not exist or you do not have the necessary access permissions!

			EOF
		return 23; fi

	# Check if tmux socket exists and is accessible
	if [[ ! -e "$SOCKET" ]]; then return 2; fi
	if [[ ! -w "$SOCKET" ]]; then caterr <<-EOF
			$(bold ERROR:) Tmux socket of $SERVER_TEXT is not accessible!

			EOF
		return 23; fi # 23 = access error

	if ! ( tmux -S "$SOCKET" has-session > /dev/null 2>&1 ); then
		# No session runs within tmux
		delete-tmux
		return 2; fi

	if ! ( tmux -S "$SOCKET" list-windows | grep "$APPNAME-server" > /dev/null ); then
		# Server is not active, most likely due to the server updating or starting up
		return 1; fi

	return 0
}

# Switch to the game console in tmux session
console () {
	status;
	local errno=$?
	if (( $errno > 1 )); then caterr <<-EOF
			$(bold ERROR:) Cannot access the console of $SERVER_TEXT!
			       Check your server's status using '$THIS_COMM @$INSTANCE status'

			EOF
		return 1; fi

	if (( $errno == 1 )); then
		tmux -S "$SOCKET" attach
	else
		tmux -S "$SOCKET" attach -t ":$APPNAME-server"
		fi

	echo
	return 0
}




