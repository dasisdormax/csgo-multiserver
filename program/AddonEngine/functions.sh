#! /bin/bash

# (C) 2016 Maximilian Wende <maximilian.wende@gmail.com>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0





::init () {
	RequestedModules=( )
	Modules=( )
}

# Add a module to the list of requested modules
# Automatically takes care of duplicates
::add () {
	array-contains "${RequestedModules[*]}" $1 || RequestedModules=( ${RequestedModules[*]} $1 )
}

# Remove a module from the list of requested modules
::remove () {
	local rm=" ${RequestedModules[*]} "
	RequestedModules=( ${rm/ $1 / } )
}

::update () {
	::unloadModules $(array-diff "${Modules[*]}" "${RequestedModules[*]}")
	::loadModules   $(array-diff "${RequestedModules[*]}" "${Modules[*]}")
}

# unloads all modules if any is set to be removed
#
# Things *may* get weird when unloading Core modules whose functions are
# still 'on the stack' and active. Only testing will find out.
::unloadModules () {
	if [[ ! $* ]]; then return 0; fi

	local module
	local funs

	# first: execute all unload handlers
	for module in $(array-reverse ${Modules[*]}); do
		::execHandler $module unload; done

	# second: delete all module functions
	# NOTE: only namespaced functions are deleted. If your module uses,
	#       non-namespaced ones, unset them in your unload handler
	for module in ${Modules[*]}; do
		funs=$(declare -f -F | grep -o "\<$module::.*$")
		[[ $funs ]] && unset -f funs; done

	Modules=( )
}

# Loads the given modules' functions, applies before and after function
# modifications and triggers their load event
::loadModules () {
	local module
	local funs
	local errno

	# first: load module functions
	for module in $*; do
		# No Namespace filtering, you have to trust the module anyway to not mess stuff up
		::execHandler $module functions && Modules=( ${Modules[*]} $module ) || errno=1; done

	# TODO: second: update function with before and after handlers

	# third: execute load handler
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
