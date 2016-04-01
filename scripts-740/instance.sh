# /bin/bash

mkdir -p "$INSTANCE_DIR/csgo"

# Directories that are fully copied, the instance owner can do whatever he wants there
cp --reflink=auto -R "$INSTALL_DIR/csgo/addons" "$INSTANCE_DIR/csgo/addons"
cp --reflink=auto -R "$INSTALL_DIR/csgo/cfg" "$INSTANCE_DIR/csgo/cfg"
cp --reflink=auto -R "$INSTALL_DIR/csgo/models" "$INSTANCE_DIR/csgo/models"
cp --reflink=auto -R "$INSTALL_DIR/csgo/sound" "$INSTANCE_DIR/csgo/sound"

# Signal that new files should not be symlinked
touch "$INSTANCE_DIR/csgo/addons/.donotlink"

# Directories where the user can add own files in addition to the provided ones
mkdir -p "$INSTANCE_DIR/csgo/maps"
mkdir -p "$INSTANCE_DIR/csgo/maps/cfg"
mkdir -p "$INSTANCE_DIR/csgo/maps/soundcache"
mkdir -p "$INSTANCE_DIR/csgo/resource/overviews"