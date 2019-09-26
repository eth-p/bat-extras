#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2019 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------
LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib"
BAT="bat"
DOCS_URL="https://github.com/eth-p/bat-extras/blob/master/doc"
source "${LIB}/opt.sh"
source "${LIB}/opt_hooks.sh"
source "${LIB}/print.sh"
source "${LIB}/pager.sh"
# -----------------------------------------------------------------------------
# Init:
# -----------------------------------------------------------------------------
hook_color
hook_pager
# -----------------------------------------------------------------------------
# Watchers:
# -----------------------------------------------------------------------------

WATCHERS=("entr")

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

watcher_entr_watch() {
	ENTR_ARGS=()

	if [[ "$OPT_CLEAR" = "true" ]]; then
		ENTR_ARGS+=('-c')
	fi

	entr "${ENTR_ARGS[@]}" \
		"$BAT" "${BAT_ARGS[@]}" \
		--terminal-width="$TERM_WIDTH" \
		--paging=never \
		"$@" \
		< <(printf "%s\n" "$@")
}

watcher_entr_supported() {
	command -v entr &>/dev/null
	return $?
}


# -----------------------------------------------------------------------------
# Functions:
# -----------------------------------------------------------------------------

determine_watcher() {
	local watcher
	for watcher in "${WATCHERS[@]}"; do
		if "watcher_${watcher}_supported"; then
			echo "$watcher"
			return 0
		fi
	done
	
	return 1
}

# -----------------------------------------------------------------------------
# Options:
# -----------------------------------------------------------------------------
BAT_ARGS=()
FILES=()
FILES_HAS_DIRECTORY=false
OPT_CLEAR=true
OPT_WATCHER=""
TERM_WIDTH="$(tput cols)"

# Set options based on tty.
if [[ -t 1 ]]; then
	OPT_COLOR=true
fi

# Parse arguments.
while shiftopt; do
	case "$OPT" in

		# Script Options
		--watcher)        shiftval; OPT_WATCHER="$OPT_VAL";;
		--clear)                    OPT_CLEAR=true;;
		--no-clear)                 OPT_CLEAR=false;;
		--terminal-width) shiftval; TERM_WIDTH="$OPT_VAL";;

		# Bat/Pager Options
		-*) BAT_ARGS+=("$OPT=$OPT_VAL");;
		
		# Files
		*) {
			FILES+=("$OPT")
		};;		

	esac
done

if [[ -z "$FILES" ]]; then
    print_error "no files provided"
    exit 1
fi

for file in "${FILES[@]}"; do
	if ! [[ -e "$file" ]]; then
		print_error "'%s' does not exist"
		exit 1
	fi

	if [[ -d "$file" ]]; then
		FILES_HAS_DIRECTORY=true
	fi
done

# Append bat arguments.
if "$OPT_COLOR"; then
	BAT_ARGS+=("--color=always")
else
	BAT_ARGS+=("--color=never")
fi

# -----------------------------------------------------------------------------
# Main:
# -----------------------------------------------------------------------------
# Determine the watcher.
if [[ -z "$OPT_WATCHER" ]]; then
	OPT_WATCHER="$(determine_watcher)"
	if [[ $? -ne 0 ]]; then
		printc "%{RED}[%s error]%{CLEAR}: Your system does not have any supported watchers.\n" "$PROGRAM" 1>&2
		printc "Please read the documentation at %{BLUE}%s%{CLEAR} for more details.\n" "$DOCS_URL/batwatch.md" 1>&2
		exit 2
	fi
fi

if ! type "watcher_${OPT_WATCHER}_supported" &>/dev/null; then
	printc "%{RED}[%s error]%{CLEAR}: Unknown watcher: '%s'\n" "$PROGRAM" "$OPT_WATCHER" 1>&2
	exit 1
fi

# Run the main function.
main() {
	"watcher_${OPT_WATCHER}_watch" "${FILES[@]}"
	return $?
}

pager_exec main
exit $?

