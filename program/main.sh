#! /bin/bash

# (C) 2016 Maximilian Wende <maximilian.wende@gmail.com>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0




main () {

######################### INITIAL CHECKS AND CALCULATIONS ########################

echo # Make some space


# Check required packages
if [[ ! -x $(which awk)  ]]; then error <<< "'awk' is not installed, but required for this script!"; return; fi
if [[ ! -x $(which tmux) ]]; then error <<< "'tmux' is not installed, but required for this script!"; return; fi
if [[ ! -x $(which wget) ]]; then error <<< "'wget' is not installed, but required for this script!"; return; fi
if [[ ! -x $(which tar)  ]]; then error <<< "'tar' is not installed, but required for this script!"; return; fi




################################### LOAD MODULES #################################

. program/Utils
. program/AddonEngine

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
	warning <<-EOF
			The configuration file for csgo-multiserver does not exist or is
			damaged. Do you want to create a new configuration now?
		EOF
	promptY "Start Setup?" && Core.Setup::beginSetup; fi


# Move to Core.Instance init handler
set-instance "$DEFAULT_INSTANCE"

Core.CommandLine::parseArguments $@

return 0

}