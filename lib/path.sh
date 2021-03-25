#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2021 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------

# Gets the file extension from a file path.
# Arguments:
#     1   -- The file path.
extname() {
	local file="$1"
	echo ".${file##*.}"
}

# Strips trailing slashes from a file path.
# Arguments:
#     1   -- The file path.
strip_trailing_slashes() {
	local file="$1"
	while [[ -n "$file" && "${file: -1}" = "/" ]]; do
		file="${file:0:$((${#file}-1))}"
	done
	echo "$file"
}
