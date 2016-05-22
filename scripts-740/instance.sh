#! /bin/bash

# (C) 2016 Maximilian Wende <maximilian.wende@gmail.com>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0

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


# Other existing files/directories are linked during the next step of the instance creation process
