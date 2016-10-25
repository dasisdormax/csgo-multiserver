#! /bin/bash

# (C) 2016 Maximilian Wende <maximilian.wende@gmail.com>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0




################################ INSTANCE HELPERS ################################

# true, if an instance exists in directory $INSTANCE_DIR
Core.Instance::isInstance () {
	[[ $(cat "$INSTANCE_DIR/msm.d/appname" 2>/dev/null) == $APP ]]
}

# true, if $INSTANCE_DIR is a base installation
Core.Instance::isBaseInstallation () {
	Core.Instance::isInstance && [[ -e $INSTANCE_DIR/msm.d/is-admin ]]
}

# true, if $INSTANCE_DIR can be used as directory for a new instance
Core.Instance::isValidDir () {
	[[ ! -e $INSTANCE_DIR ]] || [[ -d $INSTANCE_DIR && ! $(ls -A "$INSTANCE_DIR") ]]
}




###################### SERVER INSTANCE MANAGEMENT FUNCTIONS ######################

# recursively symlinks all files from the base installation that do not exist yet in the instance
# TODO: instead of checking for a donotlink file, respect App::instanceIgnoredDirs
Core.Instance::symlinkFiles () {
	# Return if .donotlink file exists in target.
	# This file could be made by instance creation scripts, to indicate that new or missing files should not be linked from the base instance again
	if [[ -e $INSTANCE_DIR/$1.donotlink ]]; then return 0; fi

	# Loop through files in directory
	for file in $(ls -A "$INSTALL_DIR/$1"); do
		# Skip files that are not readable for the current user
		if [[ ! -r $INSTALL_DIR/$1$file ]]; then continue ; fi

		# MSM directory or already symlinked files do not need any more work
		if [[ -L $INSTANCE_DIR/$1$file || $file == msm.d ]]; then continue ; fi

		# recurse through subdirectories
		if [[ -d $INSTANCE_DIR/$1$file ]]; then
			Core.Instance::symlinkFiles "${1}${file}/";
			continue ; fi

		# Create symlink for files that do not exist yet in the target directory
		if [[ ! -e $INSTANCE_DIR/$1$file ]]; then 
			ln -s "$INSTALL_DIR/$1$file" "$INSTANCE_DIR/$1$file"
			continue ; fi

		done
}


# TODO:
Core.Instance::copyFiles () {
	false
}


# TODO: Update everything
Core.Instance::create () {
	Core.Instance::isInstance && catinfo <<-EOF && return
			@$INSTANCE is already a valid instance. You can create a different
			instance using '$THIS_COMMAND @name create'

		EOF

	if ! Core.Instance::isValidDir; then
		warning <<-EOF
			The directory $(bold "$INSTANCE_DIR") is non-empty, creating an
			instance here may cause $(bold "LOSS OF DATA")!

			Please backup all important files before proceeding!

		EOF
		sleep 2
		promptN || return
	fi

	############ INSTANCE CREATION STARTS NOW ############
	mkdir -p "$INSTANCE_DIR/msm.d"

	# Execute Instance creation script. This will copy all files that the
	# instance owner should be able to modify himself.
	echo "Copying instance-specific files ..."

	Core.Instance::copyFiles

	if (( $? )); then
		caterr <<-EOF
			$(bold ERROR:) An error occured while executing the instance creation script!

			EOF
		rm -rf "$INSTANCE_DIR" > /dev/null 2>&1
		return 1; fi

	echo
	echo "Linking remaining files to the base installation ..."

	echo "$INSTALL_DIR" > "$INSTANCE_DIR/msm.d/install-dir"

	if ! symlink-all-files; then
		caterr <<-EOF
			$(bold ERROR:) Linking this instance to the base installation failed.

			EOF
		rm -rf "$INSTANCE_DIR" > /dev/null 2>&1
		return 1; fi

	echo
	echo "Performing final steps ..."

	cp "$INSTALL_DIR/msm.d/appid" "$INSTANCE_DIR/msm.d/appid"
	cp "$INSTALL_DIR/msm.d/appname" "$INSTANCE_DIR/msm.d/appname"
	cp "$SUBSCRIPT_DIR/server.conf" "$INSTANCE_DIR/msm.d/server.conf"

	# Copy gamemodes and addons from the base installation
	cp -R "$INSTALL_DIR/msm.d/modes" "$INSTANCE_DIR/msm.d/modes"
	cp -R "$INSTALL_DIR/msm.d/addons" "$INSTANCE_DIR/msm.d/addons"

	fix-permissions

	cat <<-EOF

		Instance created successfully in $(bold "$INSTANCE_DIR")!

		EOF
	catinfo <<-EOF
		$(bold INFO:)  You should now edit your instance's configuration, located in
		            $(bold "$INSTANCE_DIR/msm.d/server.conf")
		       in order to set IP, port, passwords and other game settings.

		EOF
}