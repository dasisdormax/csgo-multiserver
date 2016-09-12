#! /bin/bash

# (C) 2016 Maximilian Wende <maximilian.wende@gmail.com>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0





::init () {
	Modules=
	ActiveModules=
}

::add () {
	Modules=( ${Modules[*]//$1/} $1 )
}

::remove () {
	Modules=( ${Modules[*]//$1/} )
}

::update () {
	::unloadModules $(array-diff "${ActiveModules[*]}" "${Modules[*]}")
	::loadModules   $(array-diff "${Modules[*]}" "${ActiveModules[*]}")

	ActiveModules=( ${Modules[*]} )
}

::unloadModules () {
	local module
	local fun
	local funs

	# first: execute unload handler
	for module in $*; do
		::execHandler $module unload; done

	# second: delete module functions
	for module in $*; do
		funs=$(declare -f -F | grep -o "\<$module::")
		unset -f funs; done
}

::loadModules () {
	local module
	local fun
	local funs

	# first: load module functions
	for module in $*; do
		# TODO: Namespace filtering
		::execHandler $module functions; done

	# second: execute load handler
	for module in $*; do
		::execHandler $module load; done
}

::moduleDir () {
	local dir=${1//./\/}
	# first:  msm's program -> core modules
	# second: msm's bundled addons
	# third:  the user's own addons
	local candidates=( "$THIS_DIR/program/$dir" "$THIS_DIR/addons/$dir" "$USER_DIR/addons/$dir" )
	for dir in ${candidates[@]}; do
		[[ -d $dir ]] && echo $dir && return 0; done
	return 1
}

::execHandler () {
	local dir="$(::moduleDir $1)" && . "$dir/$2"
}

::loadApp () {
	. "apps/$APP/app.info" && . "apps/$APP/functions"
}
