#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2020 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------
# shellcheck disable=SC1090
LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo ".")")/../lib" && pwd)"
source "${LIB}/constants.sh"
source "${LIB}/print.sh"
source "${LIB}/pager.sh"
source "${LIB}/opt.sh"
source "${LIB}/opt_hook_color.sh"
source "${LIB}/opt_hook_pager.sh"
source "${LIB}/opt_hook_version.sh"
source "${LIB}/opt_hook_width.sh"
source "${LIB}/version.sh"
# -----------------------------------------------------------------------------
# Init:
# -----------------------------------------------------------------------------
hook_color
hook_pager
hook_version
hook_width
# -----------------------------------------------------------------------------
# Options:
# -----------------------------------------------------------------------------
BATDIFF_USE_DELTA="${BATDIFF_USE_DELTA:-}"

SUPPORTS_BAT_DIFF=false
SUPPORTS_DELTA=false

BAT_VERSION="$(bat_version)"
BAT_ARGS=()
DELTA_ARGS=()

FILES=()
OPT_TABS=
OPT_CONTEXT=2
OPT_ALL_CHANGES=false

# Set options based on bat version.
if version_compare "$BAT_VERSION" -ge "0.15"; then
	SUPPORTS_BAT_DIFF=true
fi

# Set options based on delta availability.
if command -v "$EXECUTABLE_DELTA" &>/dev/null; then
	SUPPORTS_DELTA=true
fi

# Parse arguments.
while shiftopt; do
	case "$OPT" in

	# bat options
	-C | --context | --diff-context)   shiftval; OPT_CONTEXT="$OPT_VAL" ;;
	--terminal-width)                  shiftval; OPT_TERMINAL_WIDTH="$OPT_VAL" ;;
	--tabs)                            shiftval; OPT_TABS="$OPT_VAL" ;;

	# Script options
	--all)                      OPT_ALL_CHANGES=true ;;
	--delta)                    BATDIFF_USE_DELTA=true ;;

	# ???
	-*) {
		printc "%{RED}%s: unknown option '%s'%{CLEAR}\n" "$PROGRAM" "$OPT" 1>&2
		exit 1
	} ;;

	# Files
	*) FILES+=("$OPT") ;;

	esac
done

# Append arguments for delta/bat.
BAT_ARGS+=("--terminal-width=${OPT_TERMINAL_WIDTH}" "--paging=never")
DELTA_ARGS+=(
	"--width=${OPT_TERMINAL_WIDTH}" 
	"--paging=never" 
	"--hunk-header-decoration-style=plain"
)

if "$OPT_COLOR"; then
	BAT_ARGS+=("--color=always")
else
	BAT_ARGS+=("--color=never")
	DELTA_ARGS+=("--theme=none")
fi

if [[ -n "$OPT_TABS" ]]; then
	BAT_ARGS+=("--tabs=${OPT_TABS}")
	DELTA_ARGS+=("--tabs=${OPT_TABS}")
fi

# -----------------------------------------------------------------------------
# Printing:
# -----------------------------------------------------------------------------
print_bat_diff() {
	local files=("$@")

	# Diff two files.
	if [[ "${#files[@]}" -eq 2 ]]; then
		diff --unified="$OPT_CONTEXT" "${files[@]}" | "$EXECUTABLE_BAT" --language=diff - "${BAT_ARGS[@]}"
		return $?
	fi

	# Diff git file.
	if "$SUPPORTS_BAT_DIFF"; then
		"$EXECUTABLE_BAT" --diff --diff-context="$OPT_CONTEXT" "${files[0]}" "${BAT_ARGS[@]}"
	else
		"$EXECUTABLE_GIT" diff -U"$OPT_CONTEXT" "${files[0]}" | "$EXECUTABLE_BAT" --language=diff - "${BAT_ARGS[@]}"
	fi
}

print_delta_diff() {
	local files=("$@")

	# Diff two files.
	if [[ "${#files[@]}" -eq 2 ]]; then
		diff --unified="$OPT_CONTEXT" "${files[@]}"  | "$EXECUTABLE_DELTA" "${DELTA_ARGS[@]}"
		return $?
	fi

	# Diff git file.
	"$EXECUTABLE_GIT" diff -U"$OPT_CONTEXT" "${files[0]}" | "$EXECUTABLE_DELTA" "${DELTA_ARGS[@]}"
}

if [[ "$BATDIFF_USE_DELTA" = "true" && "$SUPPORTS_DELTA" = "true" ]]; then
	print_diff() {
		print_delta_diff "$@"
		return $?
	}
else
	print_diff() {
		print_bat_diff "$@"
		return $?
	}
fi


# -----------------------------------------------------------------------------
# Validation:
# -----------------------------------------------------------------------------

# Handle too many files.
if [[ "${#FILES[@]}" -gt 2 ]]; then
	print_error "too many files provided"
	exit 1
fi

# Handle deprecated --all.
if "$OPT_ALL_CHANGES"; then
	print_warning "argument --all is deprecated. Use '%s' instead" "$0"
fi


# -----------------------------------------------------------------------------
# Main:
# -----------------------------------------------------------------------------
main() {
	if [[ "${#FILES[@]}" -eq 0 ]] || "$OPT_ALL_CHANGES"; then
		local file
		while read -r file; do
			if [[ -f "$file" ]]; then
				print_diff "$file"
			fi
		done < <("${EXECUTABLE_GIT}" diff --name-only --diff-filter=d)
		return
	fi

	print_diff "${FILES[@]}"
}

pager_exec main
exit $?
