#! /bin/bash

# (C) 2016 Maximilian Wende <maximilian.wende@gmail.com>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0




App::isRunnableInstance () [[ -x $INSTANCE_DIR/$SERVER_EXEC ]]


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


App::finalizeBaseInstallation () {
	true
	# cp -n "$SUBSCRIPT_DIR/server.conf" "$INSTALL_DIR/msm.d/server.conf"
	# cp -n -R "$THIS_DIR/modes-$APPID" "$INSTALL_DIR/msm.d/modes"
	# cp -n -R "$THIS_DIR/addons-$APPID" "$INSTALL_DIR/msm.d/addons"
}


App::finalizeInstance () {
	true
	# cp "$SUBSCRIPT_DIR/server.conf" "$INSTANCE_DIR/msm.d/server.conf"
	# cp -R "$INSTALL_DIR/msm.d/modes" "$INSTANCE_DIR/msm.d/modes"
	# cp -R "$INSTALL_DIR/msm.d/addons" "$INSTANCE_DIR/msm.d/addons"
}


App::applyInstancePermissions () {
	# Remove read privileges for files that may contain sensitive data
	# (such as passwords, IP addresses, etc)
	
	chmod o-r "$INSTANCE_DIR/msm.d/server.conf"
	chmod o-r "$INSTANCE_DIR/csgo/cfg/autoexec.cfg"
	chmod o-r "$INSTANCE_DIR/csgo/cfg/server.cfg"
}