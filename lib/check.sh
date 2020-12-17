#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2020 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------

# Checks that the file or directory exists.
# Arguments:
#    1  -- The path to check.
check_exists() {
	[[ -e "$1" ]] && return 0
	
	print_error "%s: No such file or directory" "$1"
	return 1
}

# Checks that the file is a file.
# Arguments:
#    1  -- The path to check.
check_is_file() {
	[[ -f "$1" ]] && return 0
	
	print_error "%s: Not a file" "$1"
	return 1
}
