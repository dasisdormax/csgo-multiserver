#! /bin/bash

# (C) 2016 Maximilian Wende <maximilian.wende@gmail.com>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0




# usage: display all the possible commands and a short explanation of what they do
# 
# Addons should at some time be able to inject their usage information into this function
Core.CommandLine::usage () { cat <<EOF
Usage: $(bold "$THIS_COMM") < commands >

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
    admin-install
             > Configure this user as his own admin, install SteamCMD,
             > and optionally download the game
    update   > Install/Update the game server
    validate > Repair broken/missing game files

Commands will be executed in the order they are given. If a command fails,
subsequent commands will not be executed.

EOF
}




##################################################################################
########################### LOOP THROUGH ALL PARAMETERS ##########################
##################################################################################

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

			( admin-install )
				admin-install || exit 0
				;;

			( * )
				# Read configuration changes and start setup if needed
				readcfg || { echo; setup; } || exit 1

				# Check other cases, but respect preconditions


				case "$1" in ############ BEGIN INNER CASE ############

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
							exit 1; fi

						echo
						;;

					( console )
						console
						;;

					( update | up | install )
						update || exit 1
						;;

					( create | create-instance )
						create-instance || exit 1
						;;

					( validate | repair )
						update validate || exit 1
						;;

					( * )
						caterr <<< "$(bold ERROR:) Unrecognized Option: $(bold "$1")."
						echo       "       Try '$THIS_COMM usage' for a list of available commands."
						echo
						exit 1
						;;

					esac ############ END INNER CASE ############
				;;

			esac ############ END OUTER CASE ############
		
		shift
	done ############ END LOOP ############

}