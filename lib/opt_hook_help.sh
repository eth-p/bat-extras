#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2019-2020 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------

# Option parser hook: --help support.
# This will accept -h or --help, which prints the usage information and exits.
hook_help() {
	SHIFTOPT_HOOKS+=("__shiftopt_hook__help")
	if [[ "$1" == "--no-short" ]]; then
		__shiftopt_hook__help() {
			if [[ "$OPT" = "--help" ]]; then
				show_help
				exit 0
			fi
	
			return 1
		}
	else
		__shiftopt_hook__help() {
			if [[ "$OPT" = "--help" ]] || [[ "$OPT" = "-h" ]]; then
				show_help
				exit 0
			fi
	
			return 1
		}
	fi
}
