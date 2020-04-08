#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2019 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------

# Option parser hook: pager support.
# This will accept --pager='pager', --no-pager
hook_pager() {
	SHIFTOPT_HOOKS+=("__shiftopt_hook__pager")
	__shiftopt_hook__pager() {
		case "$OPT" in

		# Specify paging.
		--no-pager) shiftval; SCRIPT_PAGER_CMD='' ;;
		--paging) {
			shiftval

			case "$OPT_VAL" in
			auto)   : ;;
			always) : ;;
			never)  SCRIPT_PAGER_CMD='' ;;
			*)
				printc "%{RED}%s: '--paging' expects value of 'auto', 'always', or 'never'%{CLEAR}\n" "$PROGRAM"
				exit 1
				;;
			esac
		} ;;

		# Specify the pager.
		--pager) {
			shiftval

			# [note]: These are both intentional.
			# shellcheck disable=SC2034 disable=SC2206
			{
				SCRIPT_PAGER_CMD=($OPT_VAL)
				PAGER_ARGS=()
			}
		} ;;

		*) return 1 ;;
		esac
	}
}
