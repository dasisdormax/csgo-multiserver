#! /bin/bash

# (C) 2016 Maximilian Wende <maximilian.wende@gmail.com>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0




main () {

######################### INITIAL CHECKS AND CALCULATIONS ########################

# Check required packages
[[ -x $(which awk)  ]] || error <<< "'awk' is not installed, but required for this script!"  || return
[[ -x $(which tmux) ]] || error <<< "'tmux' is not installed, but required for this script!" || return
[[ -x $(which wget) ]] || error <<< "'wget' is not installed, but required for this script!" || return
[[ -x $(which tar)  ]] || error <<< "'tar' is not installed, but required for this script!"  || return




################################### LOAD MODULES #################################

: Utils
: AddonEngine

::init

::add Core.CommandLine
::add Core.Setup
::add Core.BaseInstallation
::add Core.Instance
::add Core.ServerControl
::add Core.Wrapper

::loadApp
::update




############################# LOAD CONFIGURATION FILE ############################

if ! Core.Setup::loadConfig; then
	if [[ $MSM_DO_INSTALL == 1 ]]; then # Skip warning when installing as admin
		ADMIN=$USER Core.Setup::beginSetup || exit;
	else
		warning <<-EOF
				The configuration file for csgo-multiserver does not exist or is
				damaged. Do you want to create a new configuration now?
			EOF
		promptY "Start Setup?" && Core.Setup::beginSetup || exit
	fi
else
	echo # Make some space
	(( $# )) || Core.CommandLine::usage
fi

# Move to Core.Setup::loadConfig
set-instance "$DEFAULT_INSTANCE"

args=( "$@" )
A="$1"
Core.CommandLine::parseArguments

}