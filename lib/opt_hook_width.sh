#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2019 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------
source "${LIB}/term.sh"

# Option parser hook: --terminal-width support.
# This will accept --terminal-width=number.
#
# The variable OPT_TERMINAL_WIDTH will be set.
hook_width() {
	SHIFTOPT_HOOKS+=("__shiftopt_hook__width")
	__shiftopt_hook__width() {
		case "$OPT" in

		--terminal-width) shiftval; OPT_TERMINAL_WIDTH="$OPT_VAL" ;;

		*) return 1 ;;
		esac
		return 0
	}

	# Default terminal width.
	OPT_TERMINAL_WIDTH="$(term_width)"
}
