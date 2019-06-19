#!/usr/bin/env bash
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$1"
DIR_SRC="${HERE}/../../src"
DIR_BIN="${HERE}/../../bin"

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

