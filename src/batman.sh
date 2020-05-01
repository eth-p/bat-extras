#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2019 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------
# shellcheck disable=SC1090 disable=SC2155
LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo ".")")/../lib" && pwd)"
if [[ -n "${MANPAGER}" ]]; then BAT_PAGER="$MANPAGER"; fi
source "${LIB}/constants.sh"
source "${LIB}/pager.sh"
source "${LIB}/print.sh"
source "${LIB}/opt.sh"
source "${LIB}/opt_hook_color.sh"
source "${LIB}/opt_hook_version.sh"
# -----------------------------------------------------------------------------
hook_color
hook_version
# -----------------------------------------------------------------------------
MAN_ARGS=()
BAT_ARGS=()

while shiftopt; do
	case "$OPT" in
		--paging|--pager) shiftval; BAT_ARGS+=("${OPT}=${OPT_VAL}") ;;
		*)                          MAN_ARGS+=("$OPT") ;;
	esac
done

if "$OPT_COLOR"; then
	BAT_ARGS+=("--color=always" "--decorations=always")
else
	BAT_ARGS+=("--color=never" "--decorations=never")
fi

# -----------------------------------------------------------------------------
export MANPAGER='sh -c "col -bx | '"$(printf "%q" "$EXECUTABLE_BAT")"' --language=man --style=grid '$(printf "%q " "${BAT_ARGS[@]}")'"'
export MANROFFOPT='-c'

command man "${MAN_ARGS[@]}"
exit $?
