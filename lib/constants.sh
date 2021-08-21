#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2021 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------
if [[ -z "$__LIB_CONSTANTS_INITIALIZED" ]]; then
__LIB_CONSTANTS_INITIALIZED=true

# Constants: Executables
EXECUTABLE_BAT="$(command -v bat 2>/dev/null || command -v batcat 2>/dev/null || echo "bat")"
EXECUTABLE_GIT="git"
EXECUTABLE_DELTA="delta"
EXECUTABLE_RIPGREP="rg"
EXECUTABLE_FZF="fzf"

# Constants: Program
PROGRAM="$(basename "$0" .sh)"
PROGRAM_HOMEPAGE="https://github.com/eth-p/bat-extras"
PROGRAM_COPYRIGHT="Copyright (C) 2019-2021 eth-p | MIT License"
PROGRAM_VERSION="$({
	TOP="$(dirname "$(dirname "${BASH_SOURCE[0]}")")"
	printf "%s" "$(cat "${TOP}/version.txt" 2>/dev/null || echo "unknown")"
	if [[ -e "${TOP}/.git" ]]; then
		printf "%s-git (%s)" "" "$("${EXECUTABLE_GIT}" -C "${TOP}" rev-parse --short HEAD)"
	fi
})"

fi
