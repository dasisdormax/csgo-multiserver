#! /bin/bash

# (C) 2016 Maximilian Wende <maximilian.wende@gmail.com>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0

# This script works in the given INSTANCE_DIR
if [[ ! -d $INSTANCE_DIR ]]; then return; exit; fi

# Remove execute bit on everything but directories
chmod -R o-rw,a-x,ug+rwX "$INSTANCE_DIR"

if [[ -d $INSTANCE_DIR/.msm/clients ]]; then
	# This is a base installation
	
	# Re-add exec bit on files that need to be executable
	chmod ug+x "$INSTANCE_DIR/srcds.exe"
	chmod ug+x "$INSTANCE_DIR/srcds_linux"
	chmod ug+x "$INSTANCE_DIR/srcds_run"

	# Allow other users to read files and directories
	chmod -R o+rX "$INSTANCE_DIR"

	chmod a+rwx,g+s "$INSTANCE_DIR/.msm/clients"
fi

chmod o-r "$INSTANCE_DIR/.msm/server.conf"