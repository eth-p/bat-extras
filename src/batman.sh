#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2019 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------
LIB="$(cd "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo "${BASH_SOURCE[0]}")")" && pwd)/../lib"
BAT="bat"
source "${LIB}/print.sh"
source "${LIB}/opt.sh"
source "${LIB}/opt_hooks.sh"
# -----------------------------------------------------------------------------
hook_color
# -----------------------------------------------------------------------------
MAN_ARGS=()
BAT_ARGS=()

while shiftopt; do MAN_ARGS+=("$OPT"); done
if "$OPT_COLOR"; then
	BAT_ARGS="--color=always --decorations=always"
else
	BAT_ARGS="--color=never --decorations=never"
fi
# -----------------------------------------------------------------------------
export MANPAGER='sh -c "col -bx | '"$(printf "%q" "$BAT")"' --language=man --style=grid '"${BAT_ARGS[@]}"'"'
export MANROFFOPT='-c'

command man "${MAN_ARGS[@]}"
exit $?

