#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2019 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------
LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib"
source "${LIB}/opt.sh"
source "${LIB}/str.sh"
source "${LIB}/print.sh"
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Formatters:
# -----------------------------------------------------------------------------

FORMATTERS=("prettier")

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

formatter_prettier_supports() {
	case "$1" in
		.js|.jsx|\
		.ts|.tsx|\
		.css|.scss|.sass|\
		.html|\
		.json|\
		.md|\
		.yml)
			return 0;;
	esac
	
	return 1
}

formatter_prettier_process() {
	prettier --stdin --stdin-filepath "$1" 2>/dev/null
	return $?
}

# -----------------------------------------------------------------------------
# Functions:
# -----------------------------------------------------------------------------

# This function will map a bat `--language=...` argument into an appropriate
# file extension for the language provided. This must be hardcoded for
# performance reasons.
map_language_to_extension() {
	local ext=".txt"

	case "$1" in
		sh|bash)               ext=".sh"   ;;
		js|es6|es)             ext=".js"   ;;
		jsx)                   ext=".jsx"  ;;
		ts)                    ext=".ts"   ;;
		tsx)                   ext=".tsx"  ;;
		css)                   ext=".css"  ;;
		scss)                  ext=".scss" ;;
		sass)                  ext=".sass" ;;
		html|htm|shtml|xhtml)  ext=".html" ;;
		json)                  ext=".json" ;;
		md|mdown|markdown)     ext=".md"   ;;
		yaml|yml)              ext=".yml"  ;;
	esac
	
	echo "$ext"
}

# This function will map a file extension to a formatter.
# Formatters are defined higher up in the file.
map_extension_to_formatter() {
	local formatter
	for formatter in "${FORMATTERS[@]}"; do
		if "formatter_${formatter}_supports" "$1"; then
			echo "$formatter"
			return 0
		fi
	done
	
	echo "none"
	return 0
}

extname() {
	local file="$1"
	echo ".${file##*.}"
}

print_file() {
	if [[ "${#BAT_ARGS[@]}" -eq 0 ]]; then
		bat "$@"
		return $?
	else
		bat "${BAT_ARGS[@]}" "$@"
		return $?
	fi
}

process_file() {
	local file="$1"
	local ext="$2"
	local lang="${ext:1}"
	
	if [[ -n "$OPT_LANGUAGE" ]]; then
		lang="$OPT_LANGUAGE"
	fi

	local formatter="$(map_extension_to_formatter "$ext")"
	if [[ "$formatter" = "none" ]]; then
		print_file "$file"
		return $?
	fi

	# Prettify, then print.
	local status
	local data_raw
	local data_formatted
	if [[ "$file" = "-" ]]; then
		data_raw="$(cat -)"
		data_formatted="$("formatter_${formatter}_process" "$file" 2>/dev/null <<< "$data_raw")"
		if [[ $? -ne 0 ]]; then
			printc "{YELLOW}[%s warning]{CLEAR}: 'STDIN': Unable to format with '%s'" "$0" "$formatter" 1>&2
			print_file --language="$lang" - <<< "$data_raw"
			return 1
		fi
	else
		data_formatted="$("formatter_${formatter}_process" "$file" < "$file")"
		if [[ $? -ne 0 ]]; then
			printc "{YELLOW}[%s warning]{CLEAR}: '%s': Unable to format with '%s'" "$0" "$file" "$formatter" 1>&2
			print_file --language="$lang" "$file"
			return 1
		fi
	fi

	print_file --language="$lang" - <<< "$data_formatted"
	return $?
}

# -----------------------------------------------------------------------------
# Main:
# -----------------------------------------------------------------------------
BAT_ARGS=()
OPT_LANGUAGE=
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

# Handle input files.
FAIL=0
for file in "${FILES[@]}"; do
	if ! process_file "$file" "$(tolower "$(extname "$file")")"; then
		FAIL=1
	fi
done

# Exit.
exit $EXIT

