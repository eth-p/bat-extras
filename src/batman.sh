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

if [[ -z "${BAT_STYLE+x}" ]]; then
	export BAT_STYLE="grid"
fi

# -----------------------------------------------------------------------------
export MANPAGER='sh -c "col -bx | '"$(printf "%q" "$EXECUTABLE_BAT")"' --language=man '$(printf "%q " "${BAT_ARGS[@]}")'"'
export MANROFFOPT='-c'

# If no argument is provided and fzf is installed, use fzf to search for man pages.
if [[ "${#MAN_ARGS[@]}" -eq 0 ]] && [[ -z "$BATMAN_LEVEL" ]] && command -v "$EXECUTABLE_FZF" &>/dev/null; then
	export BATMAN_LEVEL=1
	
	selected_page="$(man -k . | "$EXECUTABLE_FZF" --delimiter=" - " --reverse -e --preview="
		echo {1} \
		| sed 's/, /\n/g;' \
		| sed 's/\([^(]*\)(\([0-9]\))/\2\t\1/' \
		| BAT_STYLE=plain xargs batman --color=always --paging=never
		" | sed 's/^\(.*\) - .*$/\1/; s/, /\n/g'
	)"
	
	if [[ -z "$selected_page" ]]; then
		exit 0
	fi
	
	# Convert the page(section) format to something that can be fed to the man command.
	while read -r line; do
		if [[ "$line" =~ ^(.*)\(([0-9]+)\)$ ]]; then
			MAN_ARGS+=("${BASH_REMATCH[2]}" "${BASH_REMATCH[1]}")
		fi
	done <<< "$selected_page"	
fi

# Run man.
command man "${MAN_ARGS[@]}"
exit $?
