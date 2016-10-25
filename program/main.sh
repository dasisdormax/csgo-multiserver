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




# TODO: add config and instance checks to all functions that require
#       them - arguments such as help should work independently

(( $# )) || Core.CommandLine::usage && {
	# Move to Core.Setup::loadConfig
	set-instance "$DEFAULT_INSTANCE"

	ARGS=( "$@" )
	A="$1"
	Core.CommandLine::parseArguments
}


} # end function main