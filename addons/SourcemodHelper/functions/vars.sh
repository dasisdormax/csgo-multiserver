#! /bin/bash
## vim: noet:sw=0:sts=0:ts=4

# Default list of plugins. If you think some should be added or removed, tell me
SM_BASE_PLUGINS="admin_flatfile adminhelp adminmenu antiflood basebans basechat basecommands basecomm basetriggers basevotes clientprefs playercommands"

SourcemodHelper::initVars () {
	SM_HOME="$USER_DIR/$APP/addons/sourcemod-helper"
	SM_FILECACHE_DIR="$SM_HOME/filecache"
	mkdir -p "$SM_FILECACHE_DIR"
}
