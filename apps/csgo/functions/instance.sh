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
	csgo/logs
	csgo/resource/overviews
EOF


# files/directories which are not shared between the base installation and the instances
App::instanceIgnoredFiles () { cat <<-EOF; }
	csgo/addons
EOF


App::finalizeInstance () (
	cd $INSTANCE_DIR/msm.d

	# copy cfg from APP_DIR
	mkdir -p cfg
	cp -n -R "$APP_DIR"/scripts/* cfg/

	# create csgo directory
	mkdir -p $INSTANCE_DIR/csgo
)


App::applyInstancePermissions () {
	# Remove read privileges for files that may contain sensitive data
	# (such as passwords, IP addresses, etc)
	
	chmod -R o-r "$INSTANCE_DIR/msm.d/cfg"
	chmod o-r "$INSTANCE_DIR/csgo/cfg/autoexec.cfg"
	chmod o-r "$INSTANCE_DIR/csgo/cfg/server.cfg"
} 2>/dev/null


App::varsToPass () { cat <<-EOF; }
	MODE
	TEAM_T
	TEAM_CT
	GSLT
	IP
	PORT
	TV_PORT
	PASS
	USE_RCON
	RCON_PASS
	TICKRATE
	SLOTS
	ADMIN_SLOTS
	TAGS
	TITLE
EOF
