#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2019 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------

# Gets the current bat version.
bat_version() {
	if [[ -z "${__BAT_VERSION}" ]]; then
		__BAT_VERSION="$(command "$EXECUTABLE_BAT" --version | cut -d ' ' -f 2)"
	fi
	
	echo "${__BAT_VERSION}"
}

# Compares two version strings.
# Arguments:
#    1  -- The version to compare.
#    2  -- The comparison operator (same as []).
#    3  -- The version to compare with.
version_compare() {
	local version="$1"
	local compare="$3"

	if ! [[ "$version" =~ \.$ ]]; then
		version="${version}."
	fi

	if ! [[ "$compare" =~ \.$ ]]; then
		compare="${compare}."
	fi

	version_compare__recurse "$version" "$2" "$compare"
	return $?
}

version_compare__recurse() {
	local version="$1"
	local operator="$2"
	local compare="$3"

	# Extract the leading number.
	local v_major="${version%%.*}"
	local c_major="${compare%%.*}"

	# Extract the remaining numbers.
	local v_minor="${version#*.}"
	local c_minor="${compare#*.}"

	# Compare the versions specially if the final number has been reached.
	if [[ -z "$v_minor" && -z "$c_minor" ]]; then
		[ "$v_major" $operator "$c_major" ];
		return $?
	fi

	# Insert zeroes where there are missing numbers.
	if [[ -z "$v_minor" ]]; then
		v_minor="0."
	fi

	if [[ -z "$c_minor" ]]; then
		c_minor="0."
	fi

	# Compare the versions.
	# This is an early escape case.
	case "$operator" in
	-eq)       [[ "$v_major" -ne "$c_major" ]] && return 1 ;;
	-ne)       [[ "$v_major" -ne "$c_major" ]] && return 0 ;;
	-ge | -gt) [[ "$v_major" -lt "$c_major" ]] && return 1
	           [[ "$v_major" -gt "$c_major" ]] && return 0 ;;
	-le | -lt) [[ "$v_major" -gt "$c_major" ]] && return 1
	           [[ "$v_major" -lt "$c_major" ]] && return 0 ;;
	esac

	version_compare__recurse "$v_minor" "$operator" "$c_minor"
}
