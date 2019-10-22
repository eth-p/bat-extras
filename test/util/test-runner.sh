#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2019 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------
# This is the test runner.
#
# It creates and sets up an environment that acts consistently and in a way
# that is optimal for testing the output of bat.
#
# It can be executed in a test script through the "$TEST_RUNNER" variable.
#
# Arguments:
#     1   -- The script to execute.
#     ... -- The arguments to pass to the script.
#
# -----------------------------------------------------------------------------
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$1"
DIR_SRC="${HERE}/../../src"
DIR_BIN="${HERE}/../../bin"

export BAT_PAGER=""
export PAGER="cat"
export TERM="xterm"
export LANG="en_US.UTF-8"
shift
case "$TEST_RUNNER_USE" in
	src)
		bash "${DIR_SRC}/${SCRIPT}.sh" "$@"
		exit $?
		;;

	bin|"")
		"${DIR_BIN}/${SCRIPT}" "$@"
		exit $?
		;;

	*)
		printf "\x1B[31mInvalid TEST_RUNNER_USE variable.\x1B[0m\n"
		printf "\x1B[31mExpects: \x1B[33msrc\x1B[31m, \x1B[33mbin\x1B[0m\n"
		exit 1
		;;
esac

