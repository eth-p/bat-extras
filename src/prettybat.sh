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
source "${LIB}/opt_hook_version.sh"
source "${LIB}/str.sh"
source "${LIB}/print.sh"
source "${LIB}/version.sh"
source "${LIB}/check.sh"
# -----------------------------------------------------------------------------
# Init:
# -----------------------------------------------------------------------------
hook_version
# -----------------------------------------------------------------------------
# Formatters:
# -----------------------------------------------------------------------------

FORMATTERS=("prettier" "rustfmt" "shfmt" "clangformat" "black")

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

formatter_prettier_supports() {
	case "$1" in
		.js | .jsx | \
		.ts | .tsx | \
		.css | .scss | .sass | \
		.graphql | .gql | \
		.html | \
		.json | \
		.md | \
		.yml)
		return 0
		;;
	esac

	return 1
}

formatter_prettier_process() {
	prettier --stdin --stdin-filepath "$1" 2>/dev/null
	return $?
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

formatter_clangformat_supports() {
	case "$1" in
	.c | .cpp | .cxx | \
		.h | .hpp | \
		.m)
		return 0
		;;
	esac

	return 1
}

formatter_clangformat_process() {
	clang-format "$1" 2>/dev/null
	return $?
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

formatter_rustfmt_supports() {
	[[ "$1" = ".rs" ]]
	return $?
}

formatter_rustfmt_process() {
	rustfmt
	return $?
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

formatter_shfmt_supports() {
	[[ "$1" = ".sh" ]]
	return $?
}

formatter_shfmt_process() {
	shfmt
	return $?
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

formatter_black_supports() {
	case "$1" in
		.py | \
		.py3 | \
		.pyw | \
		.pyi)
		return 0
		;;
	esac

	return 1
}

formatter_black_process() {
	black --code "$(cat -)"
	return $?
}

# -----------------------------------------------------------------------------
# Functions:
# -----------------------------------------------------------------------------

# This function will map a bat `--language=...` argument into an appropriate
# file extension for the language provided. This should be hardcoded for
# performance reasons.
map_language_to_extension() {
	local ext=".txt"

	case "$1" in
	sh | bash)                  ext=".sh" ;;
	js | es6 | es)              ext=".js" ;;
	jsx)                        ext=".jsx" ;;
	ts)                         ext=".ts" ;;
	tsx)                        ext=".tsx" ;;
	css)                        ext=".css" ;;
	scss)                       ext=".scss" ;;
	sass)                       ext=".sass" ;;
	html | htm | shtml | xhtml) ext=".html" ;;
	json)                       ext=".json" ;;
	md | mdown | markdown)      ext=".md" ;;
	yaml | yml)                 ext=".yml" ;;
	rust | rs)                  ext=".rs" ;;
	graphql | gql)              ext=".graphql" ;;
	python | py)                ext=".py" ;;
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
	if [[ "${#PRINT_ARGS[@]}" -eq 0 ]]; then
		"$EXECUTABLE_BAT" "$@"
		return $?
	else
		"$EXECUTABLE_BAT" "${PRINT_ARGS[@]}" "$@"
		return $?
	fi
}

process_file() {
	PRINT_ARGS=("${BAT_ARGS[@]}")
	local file="$1"
	local ext="$2"
	local fext="$ext"
	local lang="${ext:1}"
	local formatter
	
	# Check that the file exists, and is a file.
	check_exists  "$file" || return 1
	check_is_file "$file" || return 1

	# Determine the formatter.
	if [[ -n "$OPT_LANGUAGE" ]]; then
		lang="$OPT_LANGUAGE"
		fext="$(map_language_to_extension "$lang")"
	fi

	formatter="$(map_extension_to_formatter "$fext")"

	# Debug: Print the name and formatter.
	if "$DEBUG_PRINT_FORMATTER"; then
		printc "%{CYAN}%s%{CLEAR}: %s\n" "$file" "$formatter"
		return 0
	fi

	# Calculate additional print arguments.
	forward_file_name "$file"

	# Print the formatted file.
	if [[ "$formatter" = "none" ]]; then
		if [[ -z "$OPT_LANGUAGE" ]]; then
			print_file "$file"
		else
			print_file --language="$OPT_LANGUAGE" "$file"
		fi
		return $?
	fi

	# Prettify, then print.
	local data_raw
	local data_formatted

	# shellcheck disable=SC2094 disable=SC2181
	if [[ "$file" = "-" ]]; then
		data_raw="$(cat -)"
		data_formatted="$("formatter_${formatter}_process" "$file" 2>/dev/null <<<"$data_raw")"

		if [[ $? -ne 0 ]]; then
			print_warning "'STDIN': Unable to format with '%s'" "$formatter"
			print_file --language="$lang" - <<<"$data_raw"
			return 1
		fi
	else
		data_formatted="$("formatter_${formatter}_process" "$file" <"$file")"

		if [[ $? -ne 0 ]]; then
			print_warning "'%s': Unable to format with '%s'" "$file" "$formatter"
			print_file --language="$lang" "$file"
			return 1
		fi
	fi

	print_file --language="$lang" - <<<"$data_formatted"
	return $?
}

# -----------------------------------------------------------------------------
# Version-Specific Features:
# -----------------------------------------------------------------------------
BAT_VERSION="$(bat_version)"

forward_file_name() { :; }

if version_compare "$BAT_VERSION" -ge "0.14"; then
	forward_file_name() {
		PRINT_ARGS+=("--file-name" "$1")
	}
fi

# -----------------------------------------------------------------------------
# Main:
# -----------------------------------------------------------------------------
BAT_ARGS=()
OPT_LANGUAGE=
FILES=()
DEBUG_PRINT_FORMATTER=false

# Parse arguments.
while shiftopt; do
	case "$OPT" in

	# Language options
	-l)         shiftval; OPT_LANGUAGE="${OPT_VAL}" ;;
	-l*)                  OPT_LANGUAGE="${OPT:2}" ;;
	--language) shiftval; OPT_LANGUAGE="$OPT_VAL" ;;

	# Debug options
	--debug:formatter) DEBUG_PRINT_FORMATTER=true ;;

	# bat options
	-*) {
		BAT_ARGS+=("$OPT=$OPT_VAL")
	} ;;

	# Files
	*) {
		FILES+=("$OPT")
	} ;;

	esac
done

if [[ "${#FILES[@]}" -eq 0 ]]; then
	FILES=("-")
fi

# Handle input files.
FAIL=0
for file in "${FILES[@]}"; do
	if ! process_file "$file" "$(tolower "$(extname "$file")")"; then
		FAIL=1
	fi
done

# Exit.
exit "$FAIL"
