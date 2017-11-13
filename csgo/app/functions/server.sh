#! /bin/bash
## vim: noet:sw=0:sts=0:ts=4

# (C) 2016-2017 Maximilian Wende <dasisdormax@mailbox.org>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0




App::buildLaunchCommand () {
	# Read general config
	.file "$INSTCFGDIR/server.conf"

	# As "old" config files immediately generate all files and
	# the launch command, we have nothing more to do
	[[ $LAUNCH_CMD ]] && return

	# Load preset (such as gamemode, maps, ...)
	[[ $PRESET ]] && .file "$CFG_DIR/presets/$PRESET.conf"
	applyDefaults

	# Load GOTV settings
	.conf "$APP/cfg/$INSTANCE_SUFFIX/gotv.conf"

	######## Check GSLT ########
	if [[ ! $GSLT ]]; then
		warning <<-EOF
			No Game Server Login Token (GSLT) has been specified! This means that
			nobody (including yourself) will be able to connect to this server from
			the internet! Get your GSLT (AppID 730) on

				  **http://steamcommunity.com/dev/managegameservers**

			and insert it into your instance's **server.conf**.
		EOF
		promptY "Launch this server anyway?" || return
	fi

	######## PARSE MAPS AND MAPCYCLE ########

	# Convert MAPS to array
	MAPS=( ${MAPS[*]} )
	MAP=${MAP:-${MAPS[0]}}

	# TODO: handle workshop maps

	# Generate Server and GOTV titles
	TITLE=$(title)
	TITLE=${TITLE::64}
	TAGS=$(tags)
	TV_TITLE=$(tv_title)

	SLOTS=$(( MAXPLAYERS + EXTRA_SLOTS ))

	######## GENERATE SERVER CONFIG FILES ########
	App::generateServerConfig

	######## GENERATE LAUNCH COMMAND ########
	LAUNCH_ARGS=(
		-game csgo
		-console
		$USE_RCON
		-tickrate $TICKRATE

		${GSLT:++sv_setsteamaccount $GSLT} # Game Server Login Token, if set
		-port $PORT
		${LOCAL_IP:+"-ip $LOCAL_IP"}
		${WAN_IP:+"+net_public_adr $WAN_IP"}

		+game_type $GAMETYPE
		+game_mode $GAMEMODE
		+mapgroup $MAPGROUP
		+map $MAP

		-maxplayers $SLOTS

		${TV_ENABLE:+
			+tv_enable 1
			+tv_port "$TV_PORT"
			+tv_delay "$TV_DELAY"
			+tv_snapshotrate "$TV_SNAPSHOTRATE"
			+tv_maxclients "$TV_MAXCLIENTS"
		} # GOTV Settings

		${TV_RELAY:+
			+tv_relay "$TV_RELAY"
			+tv_relaypassword "$TV_RELAYPASS"
		} # GOTV RELAY SETTINGS
	)

	LAUNCH_CMD="$(quote "$INSTANCE_DIR/srcds_run" "${LAUNCH_ARGS[@]}")"
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
