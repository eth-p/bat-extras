#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2019 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------
LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib"
source "${LIB}/opt.sh"
# -----------------------------------------------------------------------------

map_language_to_extension() {
	local ext="txt"

	case "$1" in
		sh|bash)               ext="sh"   ;;
		js|es6|es)             ext="js"   ;;
		jsx)                   ext="jsx"  ;;
		ts)                    ext="ts"   ;;
		tsx)                   ext="tsx"  ;;
		css)                   ext="css"  ;;
		scss)                  ext="scss" ;;
		sass)                  ext="sass" ;;
		html|htm|shtml|xhtml)  ext="html" ;;
		json)                  ext="json" ;;
		md|mdown|markdown)     ext="md"   ;;
		yaml|yml)              ext="yml"  ;;
	esac
	
	echo "$ext"
}

# -----------------------------------------------------------------------------
PRETTIER_ARGS=()
BAT_ARGS=()
OPT_LANGUAGE=()
FILES=()

# Parse arguments.
while shiftopt; do
	case "$OPT" in

		# Language Options
		-l)         OPT_LANGUAGE="${OPT_VAL}" ;;
		-l*)        OPT_LANGUAGE="${OPT:2}"   ;;
		--language) OPT_LANGUAGE="$OPT_VAL"   ;;

		# Bat Options
		-*) {
			BAT_ARGS+=("$OPT=$OPT_VAL")
		};;
			
		# Files
		*) {
			FILES+=("$OPT")
		};;		

	esac
done

if [[ "${#FILES[@]}" -eq 0 ]]; then
	FILES="-"
fi

# Add arguments.
[[ -n "$OPT_LANGUAGE" ]] && BAT_ARGS+=("--language=$OPT_LANGUAGE") || true

# Handle input files.
prettify() {
	local status
	local formatted

	if [[ "$1" = "-" ]]; then	
		local data
		data="$(cat -)"
		formatted="$(prettier --stdin --stdin-filepath "stdin.$(map_language_to_extension "$OPT_LANGUAGE")" 2>/dev/null <<< "$data")"
		if [[ $? -ne 0 ]]; then
			echo "$data"
			return 0
		fi
	else
		formatted="$(prettier -- "$1" 2>/dev/null)"
		status=$?
	fi

	echo "$formatted"
	return $status
}

batify() {
	if [[ "${#BAT_ARGS[@]}" -eq 0 ]]; then
		bat "$@"
	else
		bat "${BAT_ARGS[@]}" "$@"
	fi
}

EXIT=0
for file in "${FILES[@]}"; do
	file_pretty="$(prettify "$file")"
	if [[ $? -eq 0 ]]; then
		batify --language="${file##*.}" - <<< "$file_pretty"
		exitcode=$?
	else 
		batify "$file"
		exitcode=$?
	fi

	if [[ $exitcode -ne 0 ]]; then
		EXIT=$exitcode
	fi
done

# Exit.
exit $EXIT

