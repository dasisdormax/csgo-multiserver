#! /bin/bash

# (C) 2016 Maximilian Wende <maximilian.wende@gmail.com>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0




# Initialization
. "$THIS_DIR/helpers.sh"

cat <<-EOF
		                           server-control.sh
		                           =================

	EOF

catinfo <<-EOF
		$(bold INFO:)  This program will control the $(bold $APPNAME) server and react to events
		       such as server crashes, pending updates and user commands.

	EOF

tmux rename-window control

while true; do
	echo "lol"
	sleep 2
	done