#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2019-2020 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------
# shellcheck disable=SC1090
LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo ".")")/../lib" && pwd)"
source "${LIB}/constants.sh"
source "${LIB}/opt.sh"
source "${LIB}/opt_hook_color.sh"
source "${LIB}/opt_hook_help.sh"
source "${LIB}/opt_hook_version.sh"
source "${LIB}/opt_hook_width.sh"
source "${LIB}/print.sh"
source "${LIB}/pager.sh"
source "${LIB}/version.sh"
# -----------------------------------------------------------------------------
# Init:
# -----------------------------------------------------------------------------
hook_color
hook_version
hook_width
hook_help
# -----------------------------------------------------------------------------
# Help:
# -----------------------------------------------------------------------------
show_help() {
	echo 'Usage: batwatch --file [--watcher entr|poll][--[no-]clear] <file> [<file> ...]'
	echo '       batwatch --command [-n<interval>] <command> [<arg> ...]' 
}
# -----------------------------------------------------------------------------
# Watchers:
# -----------------------------------------------------------------------------

WATCHERS=("entr" "poll")

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

watcher_entr_watch() {
	ENTR_ARGS=()

	if [[ "$OPT_CLEAR" == "true" ]]; then
		ENTR_ARGS+=('-c')
	fi

	entr "${ENTR_ARGS[@]}" \
		"$EXECUTABLE_BAT" "${BAT_ARGS[@]}" \
		--terminal-width="$OPT_TERMINAL_WIDTH" \
		--paging=never \
		"$@" \
		< <(printf "%s\n" "$@")
}

watcher_entr_supported() {
	command -v entr &> /dev/null
	return $?
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

POLL_STAT_VARIANT=''
POLL_STAT_COMMAND=()

determine_stat_variant() {
	if [[ -n "$POLL_STAT_VARIANT" ]]; then
		return 0
	fi

	local variant name flags ts
	for variant in "gnu -c %Z" "bsd -f %m"; do
		read    -r name flags <<< "$variant"

		# save the results of the stat command
		if read -r ts < <(stat ${flags} "$0" 2> /dev/null); then

			# verify that the value is an epoch timestamp
			# before proceeding
			if [[ "${ts}" =~ ^[0-9]+$ ]]; then
				POLL_STAT_COMMAND=(stat ${flags})
				POLL_STAT_VARIANT="$name"
				return 0
			fi
		fi
	done

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
			clear
			"$EXECUTABLE_BAT" "${BAT_ARGS[@]}" \
				--terminal-width="$OPT_TERMINAL_WIDTH" \
				--paging=never \
				"${files[@]}"

		fi

		# Check if the file has been modified.
		local i=0
		for file in "${files[@]}"; do
			time="$("${POLL_STAT_COMMAND[@]}" "$file")"

			if [[ "$time" -ne "${times[$i]}" ]]; then
				times[$i]="$time"
				modified=true
			fi

			((i++))
		done

		# Wait for "q" to exit, or check again after a few seconds.
		local input
		read -r -t "${OPT_INTERVAL}" input
		if [[ "$input" =~ [q|Q] ]]; then
			exit
		fi
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
			OPT_WATCHER="$watcher"
			return 0
		fi
	done

	return 1
}

# -----------------------------------------------------------------------------
# Options:
# -----------------------------------------------------------------------------
BAT_ARGS=(--paging=never)
FILES=()
FILES_HAS_DIRECTORY=false
OPT_MODE=file
OPT_INTERVAL=3
OPT_CLEAR=true
OPT_WATCHER=""

# Set options based on tty.
if [[ -t 1 ]]; then
	OPT_COLOR=true
fi

# Parse arguments.
while shiftopt; do
	case "$OPT" in

		# Script options
		--watcher)     shiftval;   OPT_WATCHER="$OPT_VAL" ;;
		--interval|-n) shiftval;   OPT_INTERVAL="$OPT_VAL" ;;
		--file|-f)                 OPT_MODE=file ;;
		--command|-x)              OPT_MODE=command ;;
		--clear)                   OPT_CLEAR=true ;;
		--no-clear)                OPT_CLEAR=false ;;

		# bat/Pager options
		-*) BAT_ARGS+=("$OPT=$OPT_VAL") ;;

		# Files
		*) {
			FILES+=("$OPT")
			if [[ "$OPT_MODE" = "command" ]]; then
				getargs --append FILES
				break
			fi
		} ;;

	esac
done

# Validate that a file/command was provided.
if [[ ${#FILES[@]} -eq 0 ]]; then
	if [[ "$OPT_MODE" = "file" ]]; then
		print_error "no files provided"
	else
		print_error "no command provided"
	fi
	exit 1
fi
	
# Validate that the provided files exist.
if [[ "$OPT_MODE" = "file" ]]; then
	for file in "${FILES[@]}"; do
		if ! [[ -e "$file" ]]; then
			print_error "'%s' does not exist" "$file"
			exit 1
		fi
	
		if [[ -d "$file" ]]; then
			FILES_HAS_DIRECTORY=true
		fi
	done
fi

# Append bat arguments.
if "$OPT_COLOR"; then
	BAT_ARGS+=("--color=always")
else
	BAT_ARGS+=("--color=never")
fi

# Initialize clear command based on whether or not ANSI should be used.
if [[ "$OPT_CLEAR" == "true" ]]; then
	if "$OPT_COLOR"; then
		clear() {
			term_clear || return $?
		}
	fi
else
	clear() {
		:
	}
fi

# -----------------------------------------------------------------------------
# Main:
# -----------------------------------------------------------------------------
if [[ "$OPT_MODE" = "file" ]]; then
	# Determine the watcher.
	if [[ -z "$OPT_WATCHER" ]]; then
		if ! determine_watcher; then
			print_error "Your system does not have any supported watchers."
			printc "Please read the documentation at %{BLUE}%s%{CLEAR} for more details.\n" "$PROGRAM_HOMEPAGE" 1>&2
			exit 2
		fi
	else
		if ! type "watcher_${OPT_WATCHER}_supported" &> /dev/null; then
			print_error "Unknown watcher: '%s'" "$OPT_WATCHER"
			exit 1
		fi
	
		if ! "watcher_${OPT_WATCHER}_supported" &> /dev/null; then
			print_error "Unsupported watcher: '%s'" "$OPT_WATCHER"
			exit 1
		fi
	fi
	
	main() {
		"watcher_${OPT_WATCHER}_watch"  "${FILES[@]}"
		return  $?
	}
else
	
	# Set bat's header to show the command.
	BAT_VERSION="$(bat_version)"
	if version_compare "$BAT_VERSION" -ge "0.14"; then
		BAT_ARGS+=(--file-name="${FILES[*]}")
	fi

	main() {
		while true; do
			clear
			"${FILES[@]}" 2>&1 | "$EXECUTABLE_BAT" "${BAT_ARGS[@]}"
			sleep "${OPT_INTERVAL}" || exit 1
		done
	}
fi

# Run the main function.
main
exit $?
