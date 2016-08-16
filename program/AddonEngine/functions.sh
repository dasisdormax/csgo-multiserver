#! /bin/bash

# (C) 2016 Maximilian Wende <maximilian.wende@gmail.com>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0





::init () {
	RequestedModules=
	LoadedModules=
}

::load () {
	if [[ $1 == App ]]; then
		. "apps/$APP/app.info" && ::importFuns apps/$APP
	else
		local MOD_DIR=${1//./\/}
		::importFuns program/$MOD_DIR $1 || ::importFuns addons/$MOD_DIR $1; fi
}

# Loads the functions in the given module directory (first parameter)
# in the given namespace (second parameter, to be implemented)
::importFuns () {
	. "$1/functions.sh" || . "$1/functions"
}
