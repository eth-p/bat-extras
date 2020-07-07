#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2019 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------
source "${LIB}/constants.sh"
SHIFTOPT_HOOKS=()

# Sets the internal _ARGV, _ARGV_INDEX, and _ARGV_LAST variables used when
# parsing options with the shiftopt and shiftval functions.
setargs() {
	_ARGV=("$@")
	_ARGV_LAST="$((${#_ARGV[@]} - 1))"
	_ARGV_INDEX=0
}

# Gets the next option passed to the script.
#
# Variables:
#     OPT  -- The option name.
#
# Returns:
#     0  -- An option was read.
#     1  -- No more options were read.
#
# Example:
#     while shiftopt; do
#         shiftval
#         echo "$OPT = $OPT_VAL"
#     done
shiftopt() {
	# Read the top of _ARGV.
	[[ "$_ARGV_INDEX" -gt "$_ARGV_LAST" ]] && return 1
	OPT="${_ARGV[$_ARGV_INDEX]}"
	unset OPT_VAL

	if [[ "$OPT" =~ ^--[a-zA-Z0-9_-]+=.* ]]; then
		OPT_VAL="${OPT#*=}"
		OPT="${OPT%%=*}"
	fi

	# Pop array.
	((_ARGV_INDEX++))

	# Handle hooks.
	local hook
	for hook in "${SHIFTOPT_HOOKS[@]}"; do
		if "$hook"; then
			shiftopt
			return $?
		fi
	done

	return 0
}

# Gets the value for the current option.
#
# Variables:
#     OPT_VAL  -- The option value.
#
# Returns:
#     0       -- An option value was read.
#     EXIT 1  -- No option value was available.
shiftval() {
	# Skip if a value was already provided.
	if [[ -n "${OPT_VAL+x}" ]]; then
		return 0
	fi
	
	# If it's a short flag followed by a number, use the number.
	if [[ "$OPT" =~ ^-[[:alpha:]][[:digit:]]{1,}$ ]]; then
		OPT_VAL="${OPT:2}"
		return
	fi

	OPT_VAL="${_ARGV[$_ARGV_INDEX]}"
	((_ARGV_INDEX++))

	# Error if no value is provided.
	if [[ "$OPT_VAL" =~ -.* ]]; then
		printc "%{RED}%s: '%s' requires a value%{CLEAR}\n" "$PROGRAM" "$ARG"
		exit 1
	fi
}

# -----------------------------------------------------------------------------
setargs "$@"
