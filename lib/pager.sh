#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2019 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------

# Defaults.
SCRIPT_PAGER_CMD=("$PAGER")
SCRIPT_PAGER_ARGS=()

# Add arguments for the less pager.
if [[ "$(basename "${SCRIPT_PAGER_CMD[0]}")" = "less" ]]; then
	SCRIPT_PAGER_ARGS=(-R)
fi

# Prefer the bat pager.
if [[ -n "${BAT_PAGER+x}" ]]; then
	SCRIPT_PAGER_CMD=($BAT_PAGER)
	SCRIPT_PAGER_ARGS=()
fi

# Prefer no pager if not a tty.
if ! [[ -t 1 ]]; then
	SCRIPT_PAGER_CMD=()
	SCRIPT_PAGER_ARGS=()
fi

# -----------------------------------------------------------------------------

# Parse arguments for the pager.
# This should be called inside the shiftopt/shiftval loop.
#
# Example:
#     while shiftopt; do
#         case "$OPT" in
#             # ...
#         esac
#         pager_shiftopt && continue
#     done
pager_shiftopt() {
	case "$OPT" in
		# Specify paging.
		--no-pager)   shiftval; SCRIPT_PAGER_CMD='';;
		--paging)     shiftval; {
			case "$OPT_VAL" in
				never)  SCRIPT_PAGER_CMD='';;
				always) :;;
				auto)   :;;
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

	return 0
}

# Executes a command or function, and pipes its output to the pager (if exists).
#
# Returns: The exit code of the command.
# Example:
#     pager_exec echo hi
pager_exec() {
	if [[ -n "$1" ]]; then
		if [[ -n "$SCRIPT_PAGER_CMD" ]]; then
			"$@" | "${SCRIPT_PAGER_CMD[@]}" "${SCRIPT_PAGER_ARGS[@]}"
			return $?
		else
			"$@"
			return $?
		fi
	fi
}

# Displays the output of a command or function inside the pager (if exists).
#
# Example:
#     bat | pager_display
pager_display() {
	if [[ -n "$SCRIPT_PAGER_CMD" ]]; then
		"${SCRIPT_PAGER_CMD[@]}" "${SCRIPT_PAGER_ARGS[@]}"
	else
		cat
	fi
}

