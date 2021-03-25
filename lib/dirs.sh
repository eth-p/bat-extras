#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2021 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------

# Gets a configuration directory for a command-line program.
# Arguments:
#    1   -- The program name.
config_dir() {
	if [[ -n "${XDG_CONFIG_HOME+x}" ]]; then
		echo "${XDG_CONFIG_HOME}/$1"
	else
		echo "${HOME}/.config/$1"
	fi
}
