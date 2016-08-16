#! /bin/bash

# (C) 2016 Maximilian Wende <maximilian.wende@gmail.com>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0




# A yes/no prompt. With the first parameter $1, an alternative prompt message can be given.
# returns true (0) for yes, and false (1) for no. Defaults to YES
promptY () {
	local PROMPT="Proceed?"
	if [[ $1 ]]; then local PROMPT="$1"; fi

	read -r -p "$PROMPT ($(bold Y)/n) " INPUT
	# Implicit return value below
	[[ ! $INPUT || $INPUT =~ ^([Yy]|[Yy][Ee][Ss])$ ]]
}

# A similar prompt that defaults to NO instead
promptN () {
	local PROMPT="Are you sure?"
	if [[ $1 ]]; then local PROMPT="$1"; fi
	printf "\x1b[33m"
	read -r -p "$PROMPT (y/$(bold N)) " INPUT
	printf "\x1b[m"
	# Implicit return value below
	[[ $INPUT =~ ^([Yy]|[Yy][Ee][Ss])$ ]]
}