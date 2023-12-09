#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2019 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------
# shellcheck disable=SC1090 disable=SC2155
SELF_NC="${BASH_SOURCE:-$0}"
SELF="$(cd "$(dirname "${SELF_NC}")" && cd "$(dirname "$(readlink "${SELF_NC}" || echo ".")")" && pwd)/$(basename "$(readlink "${SELF_NC}" || echo "${SELF_NC}")")"
LIB="$(cd "$(dirname "${SELF_NC}")" && cd "$(dirname "$(readlink "${SELF_NC}" || echo ".")")/../lib" && pwd)"
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
FORWARDED_ARGS=()
MAN_ARGS=()
BAT_ARGS=()

SHIFTOPT_SHORT_OPTIONS="SPLIT"
while shiftopt; do
	case "$OPT" in
		--paging|--pager) shiftval; FORWARDED_ARGS+=("${OPT}=${OPT_VAL}");
		                            BAT_ARGS+=("${OPT}=${OPT_VAL}") ;;
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
# When called as the manpager, do some preprocessing and feed everything to bat.

if [[ "${BATMAN_IS_BEING_MANPAGER:-}" = "yes" ]]; then
	print_manpage() {
		col -bx | "$EXECUTABLE_BAT" --language=man "${BAT_ARGS[@]}"
		exit $?
	}

	if [[ "${#MAN_ARGS[@]}" -eq 1 ]]; then
		# The input was passed as a file.
		cat "${MAN_ARGS[0]}" | print_manpage
	else
		# The input was passed via stdin.
		cat | print_manpage
	fi

	exit
fi

# -----------------------------------------------------------------------------
export MANPAGER="env BATMAN_IS_BEING_MANPAGER=yes bash $(printf "%q " "$SELF" "${FORWARDED_ARGS[@]}")"
export MANROFFOPT='-c'

# If no argument is provided and fzf is installed, use fzf to search for man pages.
if [[ "${#MAN_ARGS[@]}" -eq 0 ]] && [[ -z "$BATMAN_LEVEL" ]] && command -v "$EXECUTABLE_FZF" &>/dev/null; then
	export BATMAN_LEVEL=1
	
	selected_page="$(man -k . | "$EXECUTABLE_FZF" --delimiter=" - " --reverse -e --preview="
		echo {1} \
		| sed 's/, /\n/g;' \
		| sed 's/\([^(]*\)(\([0-9A-Za-z ]\))/\2\t\1/g' \
		| BAT_STYLE=plain xargs -n2 batman --color=always --paging=never 2> /dev/null
	")"
	
	if [[ -z "$selected_page" ]]; then
		exit 0
	fi
	
	# Convert the page(section) format to something that can be fed to the man command.
	while read -r line; do
		if [[ "$line" =~ ^(.*)\(([0-9a-zA-Z ]+)\) ]]; then
			MAN_ARGS+=("${BASH_REMATCH[2]}" "$(echo ${BASH_REMATCH[1]} | xargs)")
		fi
	done <<< "$selected_page"	
fi

# Run man.
command man "${MAN_ARGS[@]}"
exit $?
