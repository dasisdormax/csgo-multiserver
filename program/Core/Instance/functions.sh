#! /bin/bash

# (C) 2016 Maximilian Wende <maximilian.wende@gmail.com>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0




Core.Instance::registerCommands () {
	simpleCommand "Core.Instance::create" create create-instance
	simpleCommand "Core.Instance::setDefault" set-default
	simpleCommand "Core.Instance::listInstances" list-instances
	oneArgCommand "Core.Instance::importFrom" import-from
}




################################ INSTANCE HELPERS ################################

requireRunnableInstance () {
	requireConfig || return
	Core.Instance::isRunnableInstance || error <<-EOF
		Cannot access or run **$INSTANCE_TEXT**!

		Make sure that a) the server is properly installed and b) that
		you have the necessary privileges for that instance's directory.
	EOF
}


# true, if an instance exists in directory $INSTANCE_DIR
Core.Instance::isInstance () [[
	$(cat "$INSTANCE_DIR/msm.d/app" 2>/dev/null) == $APP
]]


Core.Instance::isRunnableInstance () {
	Core.Instance::isInstance && [[ -w "$INSTANCE_DIR" ]] && App::isRunnableInstance
}


# true, if $INSTANCE_DIR is a base installation
Core.Instance::isBaseInstallation () {
	Core.Instance::isInstance && [[ -e $INSTANCE_DIR/msm.d/is-admin ]]
}


# true, if $INSTANCE_DIR can be used as directory for a new instance
Core.Instance::isValidDir () {
	[[ ! -e $INSTANCE_DIR ]] || [[ -d $INSTANCE_DIR && ! $(ls -A "$INSTANCE_DIR") ]]
}


# update instance-related variables
Core.Instance::select () {
	if [[ $INSTANCE ]]; then
		INSTANCE_DIR="$HOME/$APP@$INSTANCE"
		INSTANCE_TEXT="Instance @$INSTANCE"
	else
		INSTANCE_DIR="$INSTALL_DIR"
		INSTANCE_TEXT="Base Installation"
	fi
	# Other locations
	TMPDIR="$INSTANCE_DIR/msm.d/tmp"
	LOGDIR="$INSTANCE_DIR/msm.d/log"
	SOCKET="$TMPDIR/server.tmux-socket"
}


Core.Instance::listInstances () (
	for file in ~/*; do
		if [[ $file =~ ~/$APP@ ]]; then
			INSTANCE="${file#~/$APP@}"
			Core.Instance::select
			Core.Instance::isInstance && echo "$INSTANCE"
		fi
	done
)




###################### SERVER INSTANCE MANAGEMENT FUNCTIONS ######################

# recursively symlinks all files from the base installation that do not exist yet in the instance
# TODO: instead of checking for a donotlink file, respect App::instanceIgnoredDirs
Core.Instance::symlinkFiles () {
	local IGNORE=" $(App::instanceIgnoredFiles) msm.d "
	local pwd="$(pwd)/"
	local dir="${pwd#"$INSTANCE_DIR/"}"
	local BASE_DIR="$INSTALL_DIR/$dir"
	debug <<< "Processing directory **$dir**"

	# Loop through files in directory
	for file in $(ls -A "$BASE_DIR"); do
		# Skip files that are not readable for the current user
		[[ ! -r $BASE_DIR$file ]] && continue

		# Skip ignored files
		[[ $IGNORE =~ " $dir$file " ]] && log <<-EOF >&3 && continue
			  --- IGNORED $dir$file.
		EOF

		# Skip existing symlinks
		[[ -L $file ]] && continue

		# recurse through subdirectories
		[[ -d $file ]] && {
			( cd $file; Core.Instance::symlinkFiles; )
			continue
		}

		# Create symlink for files that do not exist yet in the target directory
		[[ ! -e $file ]] &&	ln -s "$BASE_DIR$file" "$file" && log <<-EOF >&3
			  + SYMLINKED $dir$file.
		EOF

	done
	out <<< "" >&3
}


Core.Instance::copyFiles () {
	local file
	for file in $(App::instanceCopiedFiles); do
		local dir="$(dirname "$file")"
		[[ $dir ]] && mkdir -p "$dir"
		[[ -e $INSTALL_DIR/$file ]] && cp -R "$INSTALL_DIR/$file" "$file"
	done
}


Core.Instance::makeDirectories () {
	local dir
	# Create mixed directories
	for dir in $(App::instanceMixedDirs); do
		mkdir -p "$dir"
	done
	# Create base for ignored dirs
	for dir in $(App::instanceIgnoredFiles); do
		local dir="$(basename "$dir")"
		[[ $dir ]] && mkdir -p "$dir"
	done
}


Core.Instance::create () (

	log <<< ""
	requireConfig || return

	Core.Instance::isBaseInstallation && warning <<-EOF && return
			Directory **$INSTANCE_DIR** contains a base installation.
			Create a new instance using **$THIS_COMMAND @name create**.
		EOF

	Core.Instance::isInstance && info <<-EOF && return
			Directory **$INSTANCE_DIR** already contains a valid instance.
		EOF

	if ! Core.Instance::isValidDir; then
		warning <<-EOF
			The directory **$INSTANCE_DIR** is non-empty, creating an
			instance here may cause **LOSS OF DATA**!

			Please backup all important files before proceeding!
		EOF
		sleep 2
		promptN || return
	fi

	############ INSTANCE CREATION STARTS NOW ############
	info <<< "Creating an instance in directory **$INSTANCE_DIR** ..."

	mkdir -p "$INSTANCE_DIR" && [[ -w "$INSTANCE_DIR" ]] || {
		fatal <<< "No permission to create or write the directory **$INSTANCE_DIR**!"
		return
	}

	cd "$INSTANCE_DIR"
	rm -rf msm.d 2>/dev/null
	mkdir msm.d

	log <<< ""
	log <<< "Copying instance-specific files ..."
	Core.Instance::copyFiles

	log <<< "Creating additional directories ..."
	Core.Instance::makeDirectories

	log <<< "Linking remaining files to base installation ..."
	Core.Instance::symlinkFiles


	log <<< "Finishing instance creation ..."

	App::finalizeInstance
	App::applyInstancePermissions

	mkdir -m o-rwx "$TMPDIR" "$LOGDIR"
	echo $APP > "msm.d/app"

	success <<-EOF
		Instance created successfully! Use **$THIS_COMMAND
		@$INSTANCE set-default** to make this your default
		instance.

		Now, edit your instance's configuration file, located
		in **$INSTANCE_DIR/msm.d/server.conf**, to set IP, port,
		passwords and other game settings of your instance.
	EOF
)


Core.Instance::setDefault () {
	log <<< ""
	DEFAULT_INSTANCE="$INSTANCE"
	Core.Setup::writeConfig && {
		success <<< "Your default instance now is: **$INSTANCE_TEXT**"
	}
}


Core.Instance::importFrom () (
	[[ $1 ]] || return
	log <<< ""
	log <<< "Trying to import instances from $1 ..."
	i=0

	INSTANCES="$(
		ssh "$1" \
			MSM_REMOTE=1 APP=$APP \
			"$THIS_COMMAND" list-instances
	)"

	[[ $INSTANCES ]] || error <<-EOF || return
		Host **$1** has no instances to import!
	EOF

	for INSTANCE in $INSTANCES; do
		Core.Instance::select
		if Core.Instance::isValidDir; then
			(( i++ ))
			mkdir -p "$INSTANCE_DIR/msm.d"
			echo $APP > "$INSTANCE_DIR/msm.d/app"
			echo "$1" > "$INSTANCE_DIR/msm.d/host"
			out <<< "    Imported **$INSTANCE_TEXT** ..."
		else
			out <<< "    $INSTANCE_TEXT already exists locally."
		fi
	done

	success <<< "Imported $i new instances from $1."
)
