#! /bin/bash

# (C) 2016 Maximilian Wende <maximilian.wende@gmail.com>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0




############################### HELPER FUNCTIONS ###############################

# Shift the argument list by $1 elements
# This allows functions to use more than one parameter
argshift () {
	local n=${1-1}
	CURR_ARG="$NEXT_ARG"
	ALL_ARGS=( "${ALL_ARGS[@]:$n}" )
	NEXT_ARG="${ALL_ARGS[0]}"
	[[ $CURR_ARG ]] # Return true if an argument is available for parsing
}




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




##################################################################################
########################### LOOP THROUGH ALL PARAMETERS ##########################
##################################################################################

# TODO: Allow addons to define their own arguments and corresponding actions
Core.CommandLine::parseArguments () (

	ALL_ARGS=( "$@" )
	NEXT_ARG="$1"

	Core.Instance::select

	while argshift; do ################ BEGIN LOOP ################

		# $CURR_ARG
		#      is the current argument we're parsing
		# $ARGS
		#      is an array containing the remaining parameters

		# Functions can use 'argshift' to indicate that a parameter has
		# been used up by the function itself. This prevents the argument
		# parser to parse those parameters as commands again

		out <<-EOF >&3


			>>>>>>> Currently parsing argument: **$CURR_ARG**
		EOF

		case "$CURR_ARG" in ################ BEGIN CASE ################

			########## Display information ###########

			( info | about | license | copyright )
				about-this-program
				;;

			( help | --help | usage )
				Core.CommandLine::usage
				;;

			########## Select an instance ###########

			( @* )
				NEW_INSTANCE=${CURR_ARG:1}
				INSTANCE_ARGS=( )
				while [[ ! $NEXT_ARG =~ ^@ ]] && argshift; do
					INSTANCE_ARGS=( "${INSTANCE_ARGS[@]}" "$CURR_ARG" )
				done
				INSTANCE="$NEW_INSTANCE" Core.CommandLine::parseArguments "${INSTANCE_ARGS[@]}"
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
				error <<< "Unrecognized Option: **$CURR_ARG**" || exit
				;;

		esac ################ END CASE ################
	done ################ END LOOP ################
)