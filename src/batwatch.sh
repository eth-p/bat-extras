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
source "${LIB}/opt_hook_color.sh"
source "${LIB}/opt_hook_pager.sh"
source "${LIB}/opt_hook_version.sh"
source "${LIB}/opt_hook_width.sh"
source "${LIB}/print.sh"
source "${LIB}/pager.sh"
# -----------------------------------------------------------------------------
# Init:
# -----------------------------------------------------------------------------
# Option parser hook: --help support.
# This will accept -h or --help, which prints the usage information and exits.
hook_help() {
	SHIFTOPT_HOOKS+=("__shiftopt_hook__help")
	__shiftopt_hook__help() {
		if [[ "$OPT" = "--help" ]] || [[ "$OPT" = "-h" ]]; then
      echo 'Usage: batwatch [--watcher entr|poll][--[no-]clear] <file> [<file> ...]'
			exit 0
		fi

		return 1
	}
}

hook_color
hook_pager
hook_version
hook_width
hook_help
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

	pager_exec entr "${ENTR_ARGS[@]}" \
		"$EXECUTABLE_BAT" "${BAT_ARGS[@]}" \
		--terminal-width="$OPT_TERMINAL_WIDTH" \
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

  local varient name cmd ts

  for varient in "gnu -c %Z" "bsd -f %m"; do
    read -r name flags <<< "$varient"

    # save the results of the stat command
    if read -r ts <               \
      <( stat ${flags} "$0" 2>/dev/null ); then

      # verify that the value is an epoch timetamp
      # before proceeding
      if [[ "${ts}" =~ ^[0-9]+$ ]]; then

        POLL_STAT_COMMAND=( stat ${flags} )
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

			if [[ "$OPT_CLEAR" = "true" ]]; then
				clear
			fi

			pager_exec "$EXECUTABLE_BAT" "${BAT_ARGS[@]}" \
				--terminal-width="$OPT_TERMINAL_WIDTH" \
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

    read -r -t 1 input

    if [[ "$input" =~ [q|Q] ]]; then
      exit
    fi

    input=
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
BAT_ARGS=()
FILES=()
FILES_HAS_DIRECTORY=false
OPT_HELP=false
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
	--watcher)        shiftval; OPT_WATCHER="$OPT_VAL" ;;
	--clear)                    OPT_CLEAR=true ;;
	--no-clear)                 OPT_CLEAR=false ;;
  -h|--help)                  OPT_HELP=true ;;

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
	if ! determine_watcher; then
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

main
exit $?
