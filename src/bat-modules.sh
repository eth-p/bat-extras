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
source "${LIB}/opt.sh"
source "${LIB}/opt_hook_color.sh"
source "${LIB}/opt_hook_version.sh"
source "${LIB}/dsl.sh"
source "${LIB}/str.sh"
# -----------------------------------------------------------------------------
# Init:
# -----------------------------------------------------------------------------
hook_color
hook_version
# -----------------------------------------------------------------------------
COMMON_URL_GITHUB="https://github.com/%s.git"
COMMON_URL_GITLAB="https://gitlab.com/%s.git"
MODULES_FILE="$(bat --config-dir)/modules.txt"
# -----------------------------------------------------------------------------
# Options:
# -----------------------------------------------------------------------------
ACTION="help"

# Parse arguments.
while shiftopt; do
	case "$OPT" in

		--help)   ACTION="help" ;;
		--update) ACTION="update" ;;
		--clear)  ACTION="clear" ;;
		--setup)  ACTION="setup" ;;

		# ???
		-*) {
			printc "%{RED}%s: unknown option '%s'%{CLEAR}\n" "$PROGRAM" "$OPT" 1>&2
			exit 1
		} ;;

	esac
done

# -----------------------------------------------------------------------------
# Functions:
# -----------------------------------------------------------------------------

# Ensures that the modules file at $MODULES_FILE exists.
# If it doesn't, this will print a friendly warning and exit with exit code 1.
ensure_setup() {
	if ! [[ -f "$MODULES_FILE" ]]; then
		printc "%{YELLOW}The bat-modules modules file wasn't found.%{CLEAR}\n"
		printc "%{YELLOW}Use %{CLEAR}%s --setup%{YELLOW} to set up bat-modules, or%{CLEAR}\n" "${PROGRAM}"
		printc "%{YELLOW}read the documentation at %{CLEAR}%s%{YELLOW} for more info.%{CLEAR}\n" "${PROGRAM_HOMEPAGE}"
		exit 1
	fi
}

# Prints an error message that parsing
fail_parsing() {
	print_warning "Failed to parse bat-modules file."
	print_warning "Line %s: %s" "$DSL_LINE" "$1"
	exit 1
}

# -----------------------------------------------------------------------------
# Parsing:
# -----------------------------------------------------------------------------

dsl_on_command() {
	BM_TYPE="$(tolower "$1")"
	BM_SOURCE="$(parse_source "$2")"
	BM_OPT_CHECKOUT="master"

	case "$BM_TYPE" in
		"syntax" | "theme") : ;;
		*) fail "unknown module type '$BM_TYPE'" ;;
	esac
}

dsl_on_option() {
	# Common options.
	case "$(tolower "$1")" in
		checkout)
			BM_OPT_CHECKOUT="$2"
			return 0 ;;
	esac

	# Type-specific options.
	case "$BM_TYPE" in
		"syntax") on_option_for_syntax "$@" && return 0 ;;
		"theme")  on_option_for_theme "$@" && return 0 ;;
	esac

	# Unknown options.
	fail "unknown %s option '%s'" "$BM_TYPE" "$*"
}

on_option_for_syntax() {
	:
}

on_option_for_theme() {
	:
}

# Parses a module source.
# This takes a git url or pseudo-URL patterns such as:
#
#     example/my-syntax-on-github
#     github:example/my-syntax
#     gitlab:example/my-syntax
#
# Arguments:
#     1  -- The source string.
parse_source() {
	local source="$1"

	# shellcheck disable=SC2059
	case "$source" in
		"github:"* | "gh:"*)
			source="$(printf "$COMMON_URL_GITHUB" "$(cut -d':' -f2- <<< "$source")")"
			;;

		"gitlab:"* | "gl:"*)
			source="$(printf "$COMMON_URL_GITLAB" "$(cut -d':' -f2- <<< "$source")")"
			;;

		*)
			if [[ "$1" =~ ^([A-Za-z0-9-])+/([A-Za-z0-9-])+$ ]]; then
				parse_source "github:$1" "${@:2}"
				return $?
			fi
			;;
	esac

	echo "$source"
}

# Parses the clone directory name of a git repo URL.
# Arguments:
#     1  -- The repo URL.
parse_source_name() {
	basename "$1" .git
}

# -----------------------------------------------------------------------------
# Actions:
# -----------------------------------------------------------------------------

action:setup() {
	if ! [[ -f "$MODULES_FILE" ]]; then
cat > "$MODULES_FILE" <<-EOF
# bat-modules example file.
# See ${PROGRAM_HOMEPAGE} for documentation and help.

# syntax example/syntax

# theme https://github.com/example/theme.git
#     checkout abcdef1

EOF
	fi
	"${EDITOR:-vi}" "$MODULES_FILE"
}

action:help() {
	{
		printc "%{YELLOW}%s help:%{CLEAR}\n" "$PROGRAM"
		printc "  --clear   -- Clear the cached themes and syntaxes.\n"
		printc "  --update  -- Update themes and syntaxes.\n"
	} 1>&2
}

action:clear() {
	printc "%{YELLOW}Clearing bat syntax and theme cache...%{CLEAR}\n"
	"$EXECUTABLE_BAT" cache --clear
}

action:update() {
	dsl_on_command_commit() {
		echo "$BM_SOURCE"
	}

	# Parse the DSL.
	ensure_setup
	dsl_parse_file "$MODULES_FILE"
}

# -----------------------------------------------------------------------------
# Main:
# -----------------------------------------------------------------------------
action:"$ACTION"
exit $?
