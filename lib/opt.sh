#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2019-2020 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------
source "${LIB}/constants.sh"

# An array of functions to call before returning from `shiftopt`.
#
# If one of these functions returns a successful exit code, the
# option will be transparently skipped instead of handled.
SHIFTOPT_HOOKS=()

# A setting to change how `shiftopt` will interpret short options that consist
# of more than one character.
#
# Values:
#
#     SPLIT  -- Splits the option into multiple single-character short options.
#               "-abc" -> ("-a" "-b" "-c")
#     
#     VALUE  -- Uses the remaining characters as the value for the short option.
#               "-abc" -> ("-a=bc")
#
#     CONV   -- Converts the argument to a long option.
#               "-abc" -> ("--abc")
#
#     PASS   -- Pass the argument along as-is.
#               "-abc" -> ("-abc")
#
SHIFTOPT_SHORT_OPTIONS="VALUE"

# Sets the internal _ARGV, _ARGV_INDEX, and _ARGV_LAST variables used when
# parsing options with the shiftopt and shiftval functions.
#
# Arguments:
#     ... -- The program arguments.
# 
# Example:
#     setargs "--long=3" "file.txt"
setargs() {
	_ARGV=("$@")
	_ARGV_LAST="$((${#_ARGV[@]} - 1))"
	_ARGV_INDEX=0
	_ARGV_SUBINDEX=1
}

# Resets the internal _ARGV* variables to the original script arguments.
# This is the equivalent of storing the top-level $@ and using setargs with it.
resetargs() {
	setargs "${_ARGV_ORIGINAL[@]}"
}

# INTERNAL.
#
# Increments the argv index pointer used by `shiftopt`.  
_shiftopt_next() {
	_ARGV_SUBINDEX=1
	((_ARGV_INDEX++)) || true
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

	if [[ "$OPT" =~ ^-[a-zA-Z0-9_-]+=.* ]]; then
		OPT_VAL="${OPT#*=}"
		OPT="${OPT%%=*}"
	fi
	
	# Handle short options.
	if [[ "$OPT" =~ ^-[^-]{2,} ]]; then
		case "$SHIFTOPT_SHORT_OPTIONS" in
		 	# PASS mode: "-abc=0" -> ("-abc=0")
			PASS) _shiftopt_next ;;

			# CONV mode: "-abc=0" -> ("--abc=0")
			CONV) OPT="-${OPT}"; _shiftopt_next ;; 

			# VALUE mode: "-abc=0" -> ("-a=bc=0")
			VALUE) {
				OPT="${_ARGV[$_ARGV_INDEX]}"
				OPT_VAL="${OPT:2}"
				OPT="${OPT:0:2}"
				_shiftopt_next
			} ;; 

			# SPLIT mode: "-abc=0" -> ("-a=0" "-b=0" "-c=0")
			SPLIT) {
				OPT="-${OPT:$_ARGV_SUBINDEX:1}"
				((_ARGV_SUBINDEX++)) || true
				if [[ "$_ARGV_SUBINDEX" -gt "${#OPT}" ]]; then
					_shiftopt_next
				fi
			} ;;

			# ????? mode: Treat it as pass.
			*)
				printf "shiftopt: unknown SHIFTOPT_SHORT_OPTIONS mode '%s'" \
					"$SHIFTOPT_SHORT_OPTIONS" 1>&2
				_shiftopt_next
				;;
		esac
	else
		_shiftopt_next
	fi

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
	
	if [[ "$_ARGV_SUBINDEX" -gt 1 && "$SHIFTOPT_SHORT_OPTIONS" = "SPLIT" ]]; then
		# If it's a short group argument in SPLIT mode, we grab the next argument.
		OPT_VAL="${_ARGV[$((_ARGV_INDEX+1))]}"
	else
		# Otherwise, we can handle it normally.
		OPT_VAL="${_ARGV[$_ARGV_INDEX]}"
		_shiftopt_next
	fi

	# Error if no value is provided.
	if [[ "$OPT_VAL" =~ -.* ]]; then
		printc "%{RED}%s: '%s' requires a value%{CLEAR}\n" "$PROGRAM" "$ARG"
		exit 1
	fi
}

# -----------------------------------------------------------------------------
setargs "$@"
_ARGV_ORIGINAL=("$@")
