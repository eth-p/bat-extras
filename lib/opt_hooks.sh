#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2019 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# Hooks:
# -----------------------------------------------------------------------------

# Option parser hook: color support.
# This will accept --no-color, or --color.
# It will also try to accept --color=never|always|auto.
#
# The variable OPT_COLOR will be set depending on whether or not a TTY is
# detected and whether or not --color/--no-color is specified.
hook_color() {
	SHIFTOPT_HOOKS+=("__shiftopt_hook__color")
	__shiftopt_hook__color() {
		case "$OPT" in
			--no-color) OPT_COLOR=false; printc_init "$OPT_COLOR";;
			--color)    {
				case "$OPT_VAL" in
					auto)        :;;
					always|true) OPT_COLOR=true;  printc_init "$OPT_COLOR";;
					never|false) OPT_COLOR=false; printc_init "$OPT_COLOR";;
				esac
			};;

			*) return 1;;
		esac
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

# Option parser hook: pager support.
# This will accept --pager='pager', --no-pager
hook_pager() {
	SHIFTOPT_HOOKS+=("__shiftopt_hook__pager")
	__shiftopt_hook__pager() {
		case "$OPT" in
	    	# Specify paging.
			--no-pager)   shiftval; SCRIPT_PAGER_CMD='';;
			--paging)     shiftval; {
				case "$OPT_VAL" in
					auto)   :;;
					never)  SCRIPT_PAGER_CMD='';;
					always) :;;
				esac
			};;

			# Specify the pager.
			--pager) {
				shiftval;
				SCRIPT_PAGER_CMD=($OPT_VAL);
				PAGER_ARGS=()
			};;

			*) return 1;;
		esac
	}
}

