#! /bin/bash

# (C) 2016 Maximilian Wende <maximilian.wende@gmail.com>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0




################################## USAGE INFO ##################################

# usage: display all the possible commands and a short explanation of what they do
# 
# TODO: Allow addons to inject their usage information into this function
Core.CommandLine::usage () { bold <<EOF

Usage: **$THIS_COMMAND** < commands >

$(printf "\x1b[36m%s\x1b[m"   "**GENERAL COMMANDS:**")
    usage    > Display this help message
    info     > About this script / copyright and license information

$(printf "\x1b[36m%s\x1b[m"   "**INSTANCE SELECTION:**")
    @...     > Select the server instance to apply the following commands on.
             > If no name is given, work on the base installation instead.

    By default, the base installation is used. You may specify a different
    default \$INSTANCE in your config file.

$(printf "\x1b[36m%s\x1b[m"   "**INSTANCE-SPECIFIC COMMANDS:**")
    create   > Create a new server instance
    start | stop | restart
             > Start/Stop/Restart given server instance (using tmux)
    status   > Check whether the server is currently running
    console  > Attach (connect) to the server's console. While inside, press
             > CTRL-D to detach (return to outside) without killing the server

$(printf "\x1b[36m%s\x1b[m"   "**ADMINISTRATION COMMANDS:** working on the base installation")
    setup    > Configure this program and install dependencies
    update   > Install/Update the game server
    validate > Repair broken/missing game files

Commands will be executed in the order they are given. If a command fails,
subsequent commands will not be executed.
EOF
}



Core.CommandLine::parseArguments () {
	unset INSTANCE
	local ARGS=( )
	while [[ $1 ]]; do
		if [[ $1 =~ ^@ ]]; then
			Core.CommandLine::runOnInstance "${ARGS[@]}"
			INSTANCE="${1:1}"
			ARGS=( )
		else
			ARGS+=( $1 )
		fi
		shift
	done
	Core.CommandLine::runOnInstance "${ARGS[@]}"
}


##################################################################################
########################### LOOP THROUGH ALL PARAMETERS ##########################
##################################################################################

# TODO: Allow addons to define their own arguments and corresponding actions
Core.CommandLine::runOnInstance () (

	[[ $@ ]] || return

	INSTANCE=${INSTANCE-"$DEFAULT_INSTANCE"}
	Core.Instance::select

	out <<-EOF >&3



		==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==

		    Executing the following commands on **$INSTANCE_TEXT**:
		        $@
	EOF

	while [[ $1 ]]; do ################ BEGIN LOOP ################

		out <<-EOF >&3


			>>>>> Currently parsing argument: **$1**
		EOF

		case "$1" in ################ BEGIN CASE ################

			########## Display information ###########

			( info | about | license | copyright )
				about-this-program
				;;

			( help | --help | usage )
				Core.CommandLine::usage
				;;

			########## Initial Setup ###########

			( setup )
				Core.Setup::beginSetup
				;;

			########## Server installation / updates ##########

			( update | up | install )
				Core.BaseInstallation::requestUpdate || exit
				;;

			( validate | repair )
				Core.BaseInstallation::requestUpdate validate || exit
				;;

			########## Instance Operations ###########

			( create | create-instance )
				Core.Instance::create || exit
				;;

			########## Server Control ###########

			( start | launch )
				Core.Server::requestStart || exit
				;;

			( stop | exit )
				Core.Server::requestStop
				;;

			( restart )
				Core.Server::requestStop && Core.Server::requestStart || exit
				;;

			( status )
				Core.Server::printStatus
				;;

			( console | attach )
				Core.Server::attachToConsole
				;;

			########## Unrecognized argument ##########

			( * )
				log <<< ""
				error <<< "Unrecognized Option: **$1**" || exit
				;;

		esac ################ END CASE ################

		shift
	done ################ END LOOP ################
)
