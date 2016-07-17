#! /bin/bash

# (C) 2016 Maximilian Wende <maximilian.wende@gmail.com>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0



App::createInstanceSpecificFiles () {
	mkdir -p "$INSTANCE_DIR/csgo"

	# Directories that are fully copied, the instance owner can do whatever he wants there
	if [[ -e "$INSTALL_DIR/csgo/addons" ]]; then
		cp --reflink=auto -R "$INSTALL_DIR/csgo/addons" "$INSTANCE_DIR/csgo/addons"
		fi
	cp --reflink=auto -R "$INSTALL_DIR/csgo/cfg" "$INSTANCE_DIR/csgo/cfg"
	cp --reflink=auto -R "$INSTALL_DIR/csgo/models" "$INSTANCE_DIR/csgo/models"
	cp --reflink=auto -R "$INSTALL_DIR/csgo/sound" "$INSTANCE_DIR/csgo/sound"

	# Signal that new files should not be symlinked
	mkdir -p "$INSTANCE_DIR/csgo/addons"
	touch "$INSTANCE_DIR/csgo/addons/.donotlink"

	# Directories where the user can add own files in addition to the provided ones
	mkdir -p "$INSTANCE_DIR/csgo/maps"
	mkdir -p "$INSTANCE_DIR/csgo/maps/cfg"
	mkdir -p "$INSTANCE_DIR/csgo/maps/soundcache"
	mkdir -p "$INSTANCE_DIR/csgo/resource/overviews"
}

App::fixInstancePermissions () {
	# This script works in the given INSTANCE_DIR
	if [[ ! -d $INSTANCE_DIR ]]; then return; exit; fi

	# Remove execute bit on everything but directories
	chmod -R o-rw,a-x,ug+rwX "$INSTANCE_DIR"

	if [[ -e $INSTANCE_DIR/msm.d/is-admin ]]; then
		# This is a base installation
		
		# Re-add exec bit on files that need to be executable
		chmod ug+x "$INSTANCE_DIR/srcds_linux"
		chmod ug+x "$INSTANCE_DIR/srcds_run"

		# Allow other users to read files and directories
		chmod -R o+rX "$INSTANCE_DIR"
	fi

	# Remove read privileges for files that may contain sensitive data
	# (such as passwords, IP addresses, etc)

	chmod -R o-r "$INSTANCE_DIR/msm.d/tmp"
	chmod -R o-r "$INSTANCE_DIR/msm.d/log"
	
	chmod o-r "$INSTANCE_DIR/msm.d/server.conf"
	chmod o-r "$INSTANCE_DIR/csgo/cfg/autoexec.cfg"
	chmod o-r "$INSTANCE_DIR/csgo/cfg/server.cfg"

	# TODO: put everything that is not app specific in an own function
}