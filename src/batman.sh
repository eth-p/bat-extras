#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2019 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------
LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib"
BAT="bat"
source "${LIB}/print.sh"
source "${LIB}/opt.sh"
source "${LIB}/version.sh"
# -----------------------------------------------------------------------------

export MANPAGER='sh -c "col -bx | '"$(printf "%q" "$BAT")"' --language man --style grid"'
export MANROFFOPT='-c'
export BAT_PAGER="$PAGER"

command man "$@"
exit $?

