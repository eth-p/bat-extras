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
RG_ARGS=()
BAT_ARGS=()
PATTERN=""
FILES=()
OPT_CASE_SENSITIVITY=''
OPT_CONTEXT_BEFORE=2
OPT_CONTEXT_AFTER=2
OPT_FOLLOW=true
OPT_SNIP=""
OPT_HIGHLIGHT=true
OPT_SEARCH_PATTERN=false
OPT_FIXED_STRINGS=false
OPT_NO_SEPARATOR=false
BAT_STYLE="${BAT_STYLE:-header,numbers}"

# Set options based on the bat version.
if version_compare "$(bat_version)" -gt "0.12"; then
	OPT_SNIP=",snip"
fi

# Parse RIPGREP_CONFIG_PATH.
if [[ -n "$RIPGREP_CONFIG_PATH" && -e "$RIPGREP_CONFIG_PATH" ]]; then
	# shellcheck disable=SC2046
	setargs $(cat "$RIPGREP_CONFIG_PATH")
	while shiftopt; do
		case "$OPT" in
			-A | --after-context)  shiftval; OPT_CONTEXT_AFTER="$OPT_VAL" ;;
			-B | --before-context) shiftval; OPT_CONTEXT_BEFORE="$OPT_VAL" ;;
			-C | --context)
				shiftval
				OPT_CONTEXT_BEFORE="$OPT_VAL"
				OPT_CONTEXT_AFTER="$OPT_VAL"
				;;
		esac
	done
fi

# Parse arguments.
shopt -s extglob   # Needed to handle -u

# First handle -u specially - it can be repeated multiple times in a single
# short argument, and repeating it 1, 2, or 3 times causes different effects.
resetargs
SHIFTOPT_SHORT_OPTIONS="PASS"
while shiftopt; do
	case "$OPT" in
		[-]+(u) )
			RG_ARGS+=("$OPT")
			;;
	esac
done
resetargs
SHIFTOPT_SHORT_OPTIONS="VALUE"
while shiftopt; do
	case "$OPT" in

	# ripgrep options
	[-]+([u]) ) ;;   # Ignore - handled in first loop.
	--unrestricted)
		RG_ARGS+=("$OPT")
		;;
	-i | --ignore-case)              OPT_CASE_SENSITIVITY="--ignore-case" ;;
	-s | --case-sensitive)           OPT_CASE_SENSITIVITY="--case-sensitive" ;;
	-S | --smart-case)               OPT_CASE_SENSITIVITY="--smart-case" ;;

	-A | --after-context)  shiftval; OPT_CONTEXT_AFTER="$OPT_VAL" ;;
	-B | --before-context) shiftval; OPT_CONTEXT_BEFORE="$OPT_VAL" ;;
	-C | --context)
		shiftval
		OPT_CONTEXT_BEFORE="$OPT_VAL"
		OPT_CONTEXT_AFTER="$OPT_VAL"
		;;

	-F | --fixed-strings)
		OPT_FIXED_STRINGS=true
		RG_ARGS+=("$OPT")
		;;

	-U | --multiline | \
	-P | --pcre2 | \
	-z | --search-zip | \
	-w | --word-regexp | \
	--one-file-system | \
	--multiline-dotall | \
	--ignore | --no-ignore | \
	--crlf | --no-crlf | \
	--hidden | --no-hidden)
		RG_ARGS+=("$OPT")
		;;

	-E | --encoding | \
	-g | --glob | \
	-t | --type | \
	-T | --type-not | \
	-m | --max-count | \
	--max-depth | \
	--iglob | \
	--ignore-file)
		shiftval
		RG_ARGS+=("$OPT" "$OPT_VAL")
		;;

	# bat options

	# Script options
	--no-follow)           OPT_FOLLOW=false ;;
	--no-snip)             OPT_SNIP="" ;;
	--no-highlight)        OPT_HIGHLIGHT=false ;;
	-p | --search-pattern) OPT_SEARCH_PATTERN=true ;;
	--no-search-pattern)   OPT_SEARCH_PATTERN=false ;;
	--no-separator)        OPT_NO_SEPARATOR=true ;;

	# Option forwarding
	--rg:*) {
		if [[ "${OPT:5:1}" = "-" ]]; then
			RG_ARGS+=("${OPT:5}")
		else
			RG_ARGS+=("--${OPT:5}")
		fi
		if [[ -n "$OPT_VAL" ]]; then
			RG_ARGS+=("$OPT_VAL")
		fi
	} ;;

	# --
	--) getargs -a FILES; break ;;

	# ???
	-*) {
		printc "%{RED}%s: unknown option '%s'%{CLEAR}\n" "$PROGRAM" "$OPT" 1>&2
		exit 1
	} ;;

	# Search
	*) FILES+=("$OPT") ;;

	esac
done

# Use the first file as a pattern.
PATTERN="${FILES[0]}"
FILES=("${FILES[@]:1}")

if [[ -z "$PATTERN" ]]; then
	print_error "no pattern provided"
	exit 1
fi

# Generate separator.
SEP="$(printc "%{DIM}%${OPT_TERMINAL_WIDTH}s%{CLEAR}" | sed "s/ /─/g")"

# Append ripgrep and bat arguments.
if [[ -n "$OPT_CASE_SENSITIVITY" ]]; then
	RG_ARGS+=("$OPT_CASE_SENSITIVITY")
fi

if "$OPT_FOLLOW"; then
	RG_ARGS+=("--follow")
fi

if "$OPT_COLOR"; then
	BAT_ARGS+=("--color=always")
else
	BAT_ARGS+=("--color=never")
fi

if [[ "$OPT_CONTEXT_BEFORE" -eq 0 && "$OPT_CONTEXT_AFTER" -eq 0 ]]; then
	OPT_SNIP=""
	OPT_HIGHLIGHT=false
fi

# Handle the --search-pattern option.
if "$OPT_SEARCH_PATTERN"; then
	if is_pager_less; then
		if "$OPT_FIXED_STRINGS"; then
			# This strange character is a ^R, or Control-R, character. This instructs
			# less to NOT use regular expressions, which is what the -F flag does for
			# ripgrep. If we did not use this, then less would match a different pattern
			# than ripgrep searched for. See man less(1).
			SCRIPT_PAGER_ARGS+=(-p $'\x12'"$PATTERN")
		else
			SCRIPT_PAGER_ARGS+=(-p "$PATTERN")
		fi
	elif is_pager_disabled; then
		print_error "%s %s %s" \
			"The -p/--search-pattern option requires a pager, but" \
			"the pager was explicitly disabled by \$BAT_PAGER or the" \
			"--paging option."
		exit 1
	else
		print_error "Unsupported pager '%s' for option -p/--search-pattern" \
			"$(pager_name)"
		exit 1
	fi
fi

# -----------------------------------------------------------------------------
# Main:
# -----------------------------------------------------------------------------
main() {
	# shellcheck disable=SC2034
	FOUND_FILES=()
	FOUND=0
	FIRST_PRINT=true
	LAST_LR=()
	LAST_LH=()
	LAST_FILE=''
	READ_FROM_STDIN=false
	NO_SEPARATOR="$OPT_NO_SEPARATOR"

	if [[ "$BAT_STYLE" = *grid* ]]; then
		NO_SEPARATOR=true
	fi

	
	# If we found no files being provided and STDIN to not be attached to a tty,
	# we capture STDIN to a variable. This variable will later be written to
	# the STDIN file descriptors of both ripgrep and bat.
	if ! [[ -t 0 ]] && [[ "${#FILES[@]}" -eq 0 ]]; then
		READ_FROM_STDIN=true
		IFS='' STDIN_DATA="$(cat)"
	fi
	
	do_ripgrep_search() {
		local COMMON_RG_ARGS=(
			--with-filename \
			--vimgrep \
			"${RG_ARGS[@]}" \
			--context 0 \
			--sort path \
			-- \
			"$PATTERN" \
			"${FILES[@]}" \
		)
		
		if "$READ_FROM_STDIN"; then
			"$EXECUTABLE_RIPGREP" "${COMMON_RG_ARGS[@]}" <<< "$STDIN_DATA"
			return $?
		else
			"$EXECUTABLE_RIPGREP" "${COMMON_RG_ARGS[@]}"
			return $?
		fi
	}

	do_print() {
		[[ -z "$LAST_FILE" ]] && return 0

		# Print the separator.
		if ! "$NO_SEPARATOR"; then
			"$FIRST_PRINT" && echo "$SEP"
		fi
		FIRST_PRINT=false

		# Print the file.
		"$EXECUTABLE_BAT" "${BAT_ARGS[@]}" \
			"${LAST_LR[@]}" \
			"${LAST_LH[@]}" \
			--style="${BAT_STYLE}${OPT_SNIP}" \
			--paging=never \
			--terminal-width="$OPT_TERMINAL_WIDTH" \
			"$LAST_FILE"

		# Print the separator.
		if ! "$NO_SEPARATOR"; then
			echo "$SEP"
		fi
	}
	
	do_print_from_file_or_stdin() {
		if [[ "$LAST_FILE" = "<stdin>" ]]; then
			# If the file is from STDIN, we provide the STDIN
			# contents to bat and tell it to read from STDIN.
			LAST_FILE="-"
			do_print <<< "$STDIN_DATA"
			return $?
		else
			do_print
			return $?	
		fi
	}

	# shellcheck disable=SC2034
	while IFS=':' read -r file line column text; do
		((FOUND++))

		if [[ "$LAST_FILE" != "$file" ]]; then
			do_print_from_file_or_stdin
			LAST_FILE="$file"
			LAST_LR=()
			LAST_LH=()
		fi

		# Calculate the context line numbers.
		line_start=$((line - OPT_CONTEXT_BEFORE))
		line_end=$((line + OPT_CONTEXT_AFTER))
		[[ "$line_start" -gt 0 ]] || line_start=''

		LAST_LR+=("--line-range=${line_start}:${line_end}")
		[[ "$OPT_HIGHLIGHT" = "true" ]] && LAST_LH+=("--highlight-line=${line}")
	done < <(do_ripgrep_search)
	do_print_from_file_or_stdin

	# Exit.
	if [[ "$FOUND" -eq 0 ]]; then
		exit 2
	fi
}

pager_exec main
exit $?
