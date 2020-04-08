#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2019 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------
# shellcheck disable=SC1090
LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo ".")")/../lib" && pwd)"
source "${LIB}/constants.sh"
source "${LIB}/opt.sh"
source "${LIB}/opt_hooks.sh"
source "${LIB}/print.sh"
source "${LIB}/pager.sh"
# -----------------------------------------------------------------------------
# Init:
# -----------------------------------------------------------------------------
hook_color
hook_pager
hook_version
# -----------------------------------------------------------------------------
# Watchers:
# -----------------------------------------------------------------------------

WATCHERS=("entr" "poll")

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

watcher_entr_watch() {
	ENTR_ARGS=()

	if [[ "$OPT_CLEAR" = "true" ]]; then
		ENTR_ARGS+=('-c')
	fi

	entr "${ENTR_ARGS[@]}" \
		"$EXECUTABLE_BAT" "${BAT_ARGS[@]}" \
		--terminal-width="$TERM_WIDTH" \
		--paging=never \
		"$@" \
		< <(printf "%s\n" "$@")
}

watcher_entr_supported() {
	command -v entr &>/dev/null
	return $?
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

POLL_STAT_VARIANT=''
POLL_STAT_COMMAND=()

determine_stat_variant() {
	if [[ -n "$POLL_STAT_VARIANT" ]]; then
		return 0
	fi

	# Try GNU stat.
	if stat -c '%z' "$0" &>/dev/null; then
		POLL_STAT_COMMAND=(stat -c '%z')
		POLL_STAT_VARIANT='gnu'
		return 0
	fi

	# Try BSD stat.
	if stat -f '%m' "$0" &>/dev/null; then
		POLL_STAT_COMMAND=(stat -f '%m')
		POLL_STAT_VARIANT='bsd'
		return 0
	fi

	return 1
}

watcher_poll_watch() {
	determine_stat_variant

	local files=("$@")
	local times=()

	# Get the initial modified times.
	local file
	local time
	local modified=true
	for file in "${files[@]}"; do
		time="$("${POLL_STAT_COMMAND[@]}" "$file")"
		times+=("$time")
	done

	# Display files.
	while true; do
		if "$modified"; then
			modified=false

			if [[ "$OPT_CLEAR" = "true" ]]; then
				clear
			fi

			"$EXECUTABLE_BAT" "${BAT_ARGS[@]}" \
				--terminal-width="$TERM_WIDTH" \
				--paging=never \
				"${files[@]}"
		fi

		local i=0
		for file in "${files[@]}"; do
			time="$("${POLL_STAT_COMMAND[@]}" "$file")"

			if [[ "$time" -ne "${times[$i]}" ]]; then
				times[$i]="$time"
				modified=true
			fi

			((i++))
		done

		sleep 1
	done

	"${POLL_STAT_COMMAND[@]}" "$@"
	local ts
}

watcher_poll_supported() {
	determine_stat_variant
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

	# Script options
	--watcher)        shiftval; OPT_WATCHER="$OPT_VAL" ;;
	--clear)                    OPT_CLEAR=true ;;
	--no-clear)                 OPT_CLEAR=false ;;
	--terminal-width) shiftval; TERM_WIDTH="$OPT_VAL" ;;

	# bat/Pager options
	-*) BAT_ARGS+=("$OPT=$OPT_VAL") ;;

	# Files
	*) {
		FILES+=("$OPT")
	} ;;

	esac
done

if [[ ${#FILES[@]} -eq 0 ]]; then
	print_error "no files provided"
	exit 1
fi

for file in "${FILES[@]}"; do
	if ! [[ -e "$file" ]]; then
		print_error "'%s' does not exist" "$file"
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
	if ! OPT_WATCHER="$(determine_watcher)"; then
		print_error "Your system does not have any supported watchers."
		printc "Please read the documentation at %{BLUE}%s%{CLEAR} for more details.\n" "$PROGRAM_HOMEPAGE" 1>&2
		exit 2
	fi
else
	if ! type "watcher_${OPT_WATCHER}_supported" &>/dev/null; then
		print_error "Unknown watcher: '%s'" "$OPT_WATCHER"
		exit 1
	fi

	if ! "watcher_${OPT_WATCHER}_supported" &>/dev/null; then
		print_error "Unsupported watcher: '%s'" "$OPT_WATCHER"
		exit 1
	fi
fi

# Run the main function.
main() {
	"watcher_${OPT_WATCHER}_watch" "${FILES[@]}"
	return $?
}

pager_exec main
exit $?
