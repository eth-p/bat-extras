#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2019 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------

# Converts a string to lower case.
tolower() {
	tr "[[:upper:]]" "[[:lower:]]" <<< "$1"
}

# Converts a string to upper case.
toupper() {
	tr "[[:lower:]]" "[[:upper:]]" <<< "$1"
}

