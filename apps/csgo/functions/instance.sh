#! /bin/bash

# (C) 2016 Maximilian Wende <maximilian.wende@gmail.com>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0




# files/directories to copy fully 
App::instanceCopiedFiles () { cat <<-EOF; }
	csgo/addons
	csgo/cfg
	csgo/models
	csgo/sound
EOF


# directories, in which the user can put own files in addition to the provided ones
App::instanceMixedDirs () { cat <<-EOF; }
	csgo/maps
	csgo/maps/cfg
	csgo/maps/soundcache
	csgo/resource/overviews
EOF

# directories which are not shared between the base installation and the instances
App::instanceIgnoredDirs () { cat <<-EOF; }
	csgo/addons
EOF

App::applyBaseInstallPermissions () {
	false
}

App::applyInstancePermissions () {
	# This script works in the given INSTANCE_DIR
	Core.Instance::isInstance || return

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