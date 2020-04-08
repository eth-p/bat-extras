#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2019 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------

# Option parser hook: color support.
# This will accept --no-color or --color.
# It will also try to accept --color=never|always|auto.
#
# The variable OPT_COLOR will be set depending on whether or not a TTY is
# detected and whether or not --color/--no-color is specified.
hook_color() {
	SHIFTOPT_HOOKS+=("__shiftopt_hook__color")
	__shiftopt_hook__color() {
		case "$OPT" in

		--no-color) OPT_COLOR=false ;;
		--color) {
			case "$OPT_VAL" in
			"")            OPT_COLOR=true ;;
			always | true) OPT_COLOR=true  ;;
			never | false) OPT_COLOR=false ;;
			auto) return 0 ;;
			*)
				printc "%{RED}%s: '--color' expects value of 'auto', 'always', or 'never'%{CLEAR}\n" "$PROGRAM"
				exit 1
				;;
			esac
		} ;;

		*) return 1 ;;
		esac

		printc_init "$OPT_COLOR"
		return 0
	}

	# Default color support.
	if [[ -z "$OPT_COLOR" ]]; then
		if [[ -t 1 ]]; then
			OPT_COLOR=true
		else
			OPT_COLOR=false
		fi
		printc_init "$OPT_COLOR"
	fi
}
