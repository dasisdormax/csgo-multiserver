#! /bin/bash

# (C) 2016 Maximilian Wende <maximilian.wende@gmail.com>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0



######################### INITIAL CHECKS AND CALCULATIONS ########################

echo # Make some space


# Check required packages
if [[ ! -x $(which awk)  ]]; then caterr <<< "$(bold ERROR:) 'awk' is not installed, but required for this script!" ; echo; return 1; fi
if [[ ! -x $(which tmux) ]]; then caterr <<< "$(bold ERROR:) 'tmux' is not installed, but required for this script!"; echo; return 1; fi
if [[ ! -x $(which wget) ]]; then caterr <<< "$(bold ERROR:) 'wget' is not installed, but required for this script!"; echo; return 1; fi
if [[ ! -x $(which tar)  ]]; then caterr <<< "$(bold ERROR:) 'tar' is not installed, but required for this script!" ; echo; return 1; fi





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

NO_COMMAND=1
readcfg 2> /dev/null && set-instance "$DEFAULT_INSTANCE" || NEED_SETUP=1


Core.CommandLine::parseArguments $@


if [[ $NEED_SETUP ]]; then unset NEED_SETUP NO_COMMAND; setup; return $?; fi

if [[ $NO_COMMAND ]]; then unset NO_COMMAND; usage; return 1; fi

return 0
