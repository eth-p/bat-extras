#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2019 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------
PROGRAM="$(basename "${BASH_SOURCE[0]}")"

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
	# Ensure _ARGV exists and has the program arguments.
	if [[ -z ${_ARGV+x} ]]; then
		_ARGV=("${BASH_ARGV[@]}") 
		_ARGV_INDEX="$((${#_ARGV[@]} - 1))"
	fi

	# Read the top of _ARGV.
	[[ "$_ARGV_INDEX" -lt 0 ]] && return 1
	OPT="${_ARGV[$_ARGV_INDEX]}"
	unset OPT_VAL
	
	if [[ "$OPT" =~ ^--[a-zA-Z-]+=.* ]]; then
		OPT_VAL="${OPT#*=}"
		OPT="${OPT%%=*}"
	fi

	# Pop array.
	((_ARGV_INDEX--))
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

	OPT_VAL="${_ARGV[$_ARGV_INDEX]}"
	((_ARGV_INDEX--))

	# Error if no value is provided.
	if [[ "$OPT_VAL" =~ -.* ]]; then
		printc "%{RED}%s: '%s' requires a value%{CLEAR}\n" "$PROGRAM" "$ARG"
		exit 1
	fi
}

