#! /bin/bash

# (C) 2016 Maximilian Wende <maximilian.wende@gmail.com>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0




# usage: display all the possible commands and a short explanation of what they do
# 
# TODO: Allow addons to inject their usage information into this function
Core.CommandLine::usage () { cat <<EOF
Usage: $(bold "$THIS_COMMAND") < commands >

$(printf "\x1b[1;36m%s\x1b[m"              "GENERAL COMMANDS:")
    usage    > Display this help message
    info     > About this script / copyright and license information

$(printf "\x1b[1;36m%s\x1b[m"              "INSTANCE SELECTION:")
    @...     > Select the server instance to apply the following commands on.
             > If no name is given, work on the base installation instead.
    The default instance \$DEFAULT_INSTANCE can be specified in the config file

$(printf "\x1b[1;36m%s\x1b[m"              "INSTANCE-SPECIFIC COMMANDS:")
    create   > Create a new server instance
    start | stop | restart
             > Start/Stop/Restart given server instance (using tmux)
    status   > Check whether the server is currently running
    console  > Attach (connect) to the server's console. While inside, press
             > CTRL-D to detach (return to outside) without killing the server

$(printf "\x1b[1;36m%s\x1b[22m %s\x1b[m"   "ADMINISTRATION COMMANDS:" "(regarding the base installation)")
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
Core.CommandLine::parseArguments () {

	while [[ $1 ]]; do
		unset NEED_SETUP
		unset NO_COMMAND

		case "$1" in ############ BEGIN OUTER CASE ############

			( info | about | license | copyright )
				about-this-program
				;;

			( help | --help | usage )
				Core.CommandLine::usage
				;;

			( @* )
				set-instance ${1:1}
				;;

			( start | launch )
				start || exit 1
				;;

			( stop | exit )
				stop || exit 1
				;;

			( restart )
				stop &&	start || exit 1
				;;

			( status )
				status
				errno=$?
				if (( $errno == 0 )); then
					echo "$SERVER_TEXT is RUNNING!"
				elif (( $errno == 1 )); then
					echo "$SERVER_TEXT is currently LAUNCHING or UPDATING!"
				elif (( $errno == 2 )); then
					echo "$SERVER_TEXT is STOPPED!"
				else
					exit 1
				fi

				echo
				;;

			( console )
				console
				;;

			( update | up | install )
				Core.BaseInstallation::requestUpdate || exit
				;;

			( create | create-instance )
				create-instance || exit
				;;

			( validate | repair )
				Core.BaseInstallation::requestUpdate validate || exit
				;;

			( * )
				error <<< "Unrecognized Option: $(bold "$1")" || exit
				;;

		esac ############ END OUTER CASE ############
		
	shift
done ############ END LOOP ############

}