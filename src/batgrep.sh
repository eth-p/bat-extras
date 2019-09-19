#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2019 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------
LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib"
BAT="bat"
source "${LIB}/print.sh"
source "${LIB}/opt.sh"
source "${LIB}/version.sh"
# -----------------------------------------------------------------------------
SEP="$(printc "%{DIM}%$(tput cols)s%{CLEAR}" | sed "s/ /─/g")"
RG_ARGS=()
BAT_ARGS=()
PATTERN=
FILES=()
OPT_CONTEXT_BEFORE=2
OPT_CONTEXT_AFTER=2
OPT_FOLLOW=true
OPT_SNIP=""
OPT_HIGHLIGHT=true
BAT_STYLE="header,numbers"

# Set options based on the bat version.
if version_compare "$(bat_version)" -gt "0.12"; then
	OPT_SNIP=",snip"
fi

# Parse arguments.
while shiftopt; do
	case "$OPT" in

		# Ripgrep Options
		-i|--ignore-case)    RG_ARGS+=("--ignore-case");;
		-A|--after-context)  shiftval; OPT_CONTEXT_AFTER="$OPT_VAL";;
		-B|--before-context) shiftval; OPT_CONTEXT_BEFORE="$OPT_VAL";;
		-C|--context)        shiftval; OPT_CONTEXT_BEFORE="$OPT_VAL";
			                           OPT_CONTEXT_AFTER="$OPT_VAL";;

		-F|--fixed-strings|\
		-U|--multiline|\
		-P|--pcre2|\
		-z|--search-zip|\
		-w|--word-regexp|\
		--one-file-system|\
		--multiline-dotall|\
		--ignore|--no-ignore|\
		--crlf|--no-crlf|\
		--hidden|--no-hidden)          RG_ARGS+=("$OPT");;

		-E|--encoding|\
		-g|--glob|\
		-t|--type|\
		-T|--type-not|\
		-m|--max-count|\
		--max-depth|\
		--iglob|\
		--ignore-file)       shiftval; RG_ARGS+=("$OPT" "$OPT_VAL");;

		# Bat Options
		
		# Script Options
		--no-follow)                   OPT_FOLLOW=false;;
		--no-snip)                     OPT_SNIP="";;
		--no-highlight)                OPT_HIGHLIGHT=false;;

		# ???
		-*) {
			printc "%{RED}%s: unknown option '%s'%{CLEAR}\n" "$PROGRAM" "$OPT" 1>&2
			exit 1
		};;

		# Search
		*) {
			if [ -z "$PATTERN" ]; then
				PATTERN="$OPT"
			else
				FILES+=("$OPT")
			fi
		};;		
	esac
done

if [[ -z "$PATTERN" ]]; then
	printc "%{RED}%s: no pattern provided%{CLEAR}\n" "$PROGRAM" 1>&2
	exit 1
fi

if "$OPT_FOLLOW"; then
	RG_ARGS+=("--follow")	
fi

if [[ "$OPT_CONTEXT_BEFORE" -eq 0 && "$OPT_CONTEXT_AFTER" -eq 0 ]]; then
	OPT_SNIP=""
	OPT_HIGHLIGHT=false
fi

# Invoke ripgrep.
FOUND_FILES=()
FOUND=0
FIRST_PRINT=true
LAST_LR=()
LAST_LH=()
LAST_FILE=''

do_print() {
	[[ -z "$LAST_FILE" ]] && return 0

	# Print the separator.
	"$FIRST_PRINT" && echo "$SEP"
	FIRST_PRINT=false

	# Print the file.
	"$BAT" "${BAT_ARGS[@]}" \
		   "${LAST_LR[@]}" \
		   "${LAST_LH[@]}" \
		   --style="${BAT_STYLE}${OPT_SNIP}" \
		   --paging=never \
		   "$LAST_FILE"

	# Print the separator.
	echo "$SEP"
}

while IFS=':' read -r file line column; do
	((FOUND++))

	if [[ "$LAST_FILE" != "$file" ]]; then
		do_print
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
done < <(rg --with-filename --vimgrep "${RG_ARGS[@]}" --sort path "$PATTERN" "${FILES[@]}")
do_print

# Exit.
if [[ "$FOUND" -eq 0 ]]; then
	exit 2
fi

