#! /bin/bash

# (C) 2016 Maximilian Wende <maximilian.wende@gmail.com>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0





AddonEngine::loadModule () {
	local MOD_DIR=${1//./\/}
	if [[ $1 =~ ^App$|^Addon|^AE$ ]]; then return 1; fi
	   
	   AddonEngine::loadModuleFunctions program/$MOD_DIR $1 \
	|| AddonEngine::loadModuleFunctions addons/$MOD_DIR $1
}

AddonEngine::loadApp () {
	. "apps/$APP/app.info" && AddonEngine::loadModuleFunctions apps/$APP
}

# Loads the functions in the given module directory (first parameter)
# in the given namespace (second parameter, to be implemented)
AddonEngine::loadModuleFunctions () {
	. "$1/functions.sh" || . "$1/functions"
}