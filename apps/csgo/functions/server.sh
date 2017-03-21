#! /bin/bash

# (C) 2016 Maximilian Wende <maximilian.wende@gmail.com>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0




App::buildLaunchCommand () {
	# TODO: put those files in a proper location
	. "$INSTANCE_DIR/msm.d/cfg/server.conf"
}


# Announces an update which will cause the server to shut down
App::announceUpdate () {
	tmux-send -t ":$APP-server" <<-EOF
		say "This server is shutting down for an update soon. See you later!"
	EOF
}

# Ask the server to shut down
App::shutdownServer () {
	tmux-send -t ":$APP-server" <<-EOF
		exit
	EOF
}