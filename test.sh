#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2019 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="${HERE}/lib"
source "${LIB}/opt.sh"
# -----------------------------------------------------------------------------
cd "$HERE"

# -----------------------------------------------------------------------------
export TEST_ENV_LIB="${HERE}/lib"
export TEST_ENV_BIN_DIR="${HERE}/src"
export TEST_ENV_BIN_SUFFIX=".sh"
export TEST_DIR="${HERE}/test/suite"
export TEST_PWD="${HERE}/test/data"
export TEST_SHIM_PATH="${HERE}/test/shim"
export SNAPSHOT_DIR="${HERE}/test/snapshot"

OPT_ARGV=()
while shiftopt; do
	case "$OPT" in
		--compiled) TEST_ENV_BIN_DIR="${HERE}/bin"; TEST_ENV_BIN_SUFFIX="" ;;
		*)          OPT_ARGV+=("$OPT") ;;
	esac
done

# -----------------------------------------------------------------------------
# Initialize submodule if it isn't already.
if ! [[ -f "${HERE}/.test-framework/bin/best.sh" ]]; then
	git submodule init '.test-framework'
	git submodule update
fi

# Run best.
exec "${HERE}/.test-framework/bin/best.sh" "${OPT_ARGV[@]}"
