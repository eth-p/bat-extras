#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2021 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------
#
# EXTERNAL VIEWERS FOR BATPIPE:
#
#     External viewers can be added to batpipe by creating bash scripts
#     inside the `~/.config/batpipe/viewers.d/` directory.
#
# CREATING A VIEWER:
#
#      Viewers must define two functions and append the viewer's name to the
#      `BATPIPE_VIEWERS` array.
#
#      - viewer_${viewer}_supports [file_basename] [file_path] [inner_file_path]
#        If this returns 0, the viewer's process function will be used.
#
#      - viewer_${viewer}_process  [file_path] [inner_file_path]
#
# VIEWER API:
#
#     $BATPIPE_VIEWERS      -- An array of loaded file viewers.
#     $BATPIPE_ENABLE_COLOR -- Whether color is supported. (`true`|`false`)
#     $BATPIPE_INSIDE_LESS  -- Whether batpipe is inside less. (`true`|`false`)
#     $TERM_WIDTH           -- The terminal width. (only supported in `less`)
#
#     batpipe_header [pattern] [...]    -- Print a viewer header line.
#     batpipe_subheader [pattern] [...] -- Print a viewer subheader line.
#
#     bat                   -- Use `bat` for highlighting.
#     bat_if_not_bat [...]  -- Use `bat` for highlighting (when running from `less`).
#
#     strip_trailing_slashes [path]     -- Strips trailing slashes from a path.
#
# -----------------------------------------------------------------------------
# shellcheck disable=SC1090 disable=SC2155
SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo ".")")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo ".")")/../lib" && pwd)"
source "${LIB}/constants.sh"
source "${LIB}/dirs.sh"
source "${LIB}/str.sh"
source "${LIB}/print.sh"
source "${LIB}/path.sh"
source "${LIB}/proc.sh"
source "${LIB}/opt.sh"
source "${LIB}/version.sh"
source "${LIB}/term.sh"
# -----------------------------------------------------------------------------
# Usage/Install:
# -----------------------------------------------------------------------------

if [[ "$#" -eq 0 ]]; then
	# If writing to a terminal, display instructions and help.
	if [[ -t 1 ]]; then
		printc "%{DIM}# %s, %s.\n# %s\n# %s\n# %s\n# \n# %s%{CLEAR}\n" \
			"$PROGRAM" \
			"a bat-based preprocessor for less and bat" \
			"Version: $PROGRAM_VERSION" \
			"Homepage: $PROGRAM_HOMEPAGE" \
			"$PROGRAM_COPYRIGHT" \
			"To use $PROGRAM, eval the output of this command in your shell init script."
	fi

	# Detect the shell.
	#
	# This will directly check if the parent is fish, since there's a
	# good chance that `bash` or `sh` will be invoking fish.
	if [[ "$(basename -- "$(parent_executable | cut -f1 -d' ')")" == "fish" ]]; then
		detected_shell="fish"
	else
		detected_shell="$(parent_shell)"
	fi

	# Print the commands required to add `batpipe` to the environment variables.
	case "$(basename -- "${detected_shell:bash}")" in
		fish) # Fish
			printc '%{YELLOW}set -x %{CLEAR}LESSOPEN %{CYAN}"|%q %%s"%{CLEAR};\n' "$SELF"
			printc '%{YELLOW}set -e %{CLEAR}LESSCLOSE;\n'
			;;
		*) # Bash-like
			printc '%{YELLOW}LESSOPEN=%{CYAN}"|%s %%s"%{CLEAR};\n' "$SELF"
			printc '%{YELLOW}export%{CLEAR} LESSOPEN\n' "$SELF"
			printc '%{YELLOW}unset%{CLEAR} LESSCLOSE;\n'
			;;
	esac
	exit 0
fi

# -----------------------------------------------------------------------------
# Init:
# -----------------------------------------------------------------------------
BATPIPE_INSIDE_LESS=false
BATPIPE_INSIDE_BAT=false
TERM_WIDTH="$(term_width)"

bat_if_not_bat() { cat; }
if [[ "$(basename -- "$(parent_executable "$(parent_executable_pid)"|cut -f1 -d' ')")" == less ]]; then
	BATPIPE_INSIDE_LESS=true
	bat_if_not_bat() { bat "$@"; return $?; }
elif [[ "$(basename -- "$(parent_executable|cut -f1 -d' ')")" == "$(basename -- "$EXECUTABLE_BAT")" ]]; then
	BATPIPE_INSIDE_BAT=true
fi

# -----------------------------------------------------------------------------
# Viewers:
# -----------------------------------------------------------------------------

BATPIPE_VIEWERS=("exa" "ls" "tar" "unzip" "gunzip" "xz")

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

viewer_exa_supports() {
	[[ -d "$2" ]] || return 1
	command -v "exa" &> /dev/null || return 1
	return 0
}

viewer_exa_process() {
	local dir="$(strip_trailing_slashes "$1")"
	batpipe_header "Viewing contents of directory: %{PATH}%s" "$dir"
	if "$BATPIPE_ENABLE_COLOR"; then
		exa -la --color=always "$1" 2>&1
	else
		exa -la --color=never "$1" 2>&1
	fi
	return $?
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

viewer_ls_supports() {
	[[ -d "$2" ]]
	return $?
}

viewer_ls_process() {
	local dir="$(strip_trailing_slashes "$1")"
	batpipe_header "Viewing contents of directory: %{PATH}%s" "$dir"
	ls -lA "$1" 2>&1
	return $?
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

viewer_tar_supports() {
	command -v "tar" &> /dev/null || return 1

	case "$1" in
		*.tar | *.tar.*) return 0 ;;
	esac

	return 1
}

viewer_tar_process() {
	if [[ -n "$2" ]]; then
		tar -xf "$1" -O "$2" | bat_if_not_bat --file-name="$1/$2" 
	else
		batpipe_header    "Viewing contents of archive: %{PATH}%s" "$1"
		batpipe_subheader "To view files within the archive, add the file path after the archive."
		tar -tvf "$1"
		return $?
	fi
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

viewer_unzip_supports() {
	command -v "unzip" &> /dev/null || return 1

	case "$1" in
		*.zip) return 0 ;;
	esac

	return 1
}

viewer_unzip_process() {
	if [[ -n "$2" ]]; then
		unzip -p "$1" "$2" | bat_if_not_bat --file-name="$1/$2" 
	else
		batpipe_header    "Viewing contents of archive: %{PATH}%s" "$1"
		batpipe_subheader "To view files within the archive, add the file path after the archive."
		unzip -l "$1"
		return $?
	fi
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

viewer_gunzip_supports() {
	command -v "gunzip" &> /dev/null || return 1
	[[ -z "$3" ]] || return 1

	case "$2" in
		*.gz) return 0 ;;
	esac

	return 1
}

viewer_gunzip_process() {
	gunzip -k -c "$1"
	return $?
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

viewer_xz_supports() {
	command -v "xz" &> /dev/null || return 1
	[[ -z "$3" ]] || return 1

	case "$2" in
		*.xz) return 0 ;;
	esac

	return 1
}

viewer_xz_process() {
	xz --decompress -k -c "$1"
	return $?
}

# -----------------------------------------------------------------------------
# Functions:
# -----------------------------------------------------------------------------

# Print a header for batpipe messages.
# Arguments:
#     1   -- The printc formatting string.
#     ... -- The printc formatting arguments.
batpipe_header() {
	local pattern="${1//%{C\}/%{C\}%{HEADER\}}"
	printc "%{HEADER}==> $pattern%{C}\n" "${@:2}"
}

# Print a subheader for batpipe messages.
# Arguments:
#     1   -- The printc formatting string.
#     ... -- The printc formatting arguments.
batpipe_subheader() {
	local pattern="${1//%{C\}/%{C\}%{SUBHEADER\}}"
	printc "%{SUBHEADER}==> $pattern%{C}\n" "${@:2}"
}

bat() {
	# Conditionally enable forwarding of certain arguments.
	if [[ -z "$__BAT_VERSION" ]]; then
		__BAT_VERSION="$(bat_version)"
		
		__bat_forward_arg_file_name() { :; }
		
		if version_compare "$__BAT_VERSION" -ge "0.14"; then
			__bat_forward_arg_file_name() {
				__bat_forward_args+=("--file-name" "$1")
			}
		fi
	fi
	
	# Parse arguments intended for bat.
	__bat_batpipe_args=()
	__bat_forward_args=()
	setargs "$@"
	while shiftopt; do
		case "$OPT" in
			--file-name) shiftval; __bat_forward_arg_file_name "$OPT_VAL";;

			# Disallowed forwarding.
			--paging)            shiftval;;
			--decorations)       shiftval;;
			--style)             shiftval;;
			--terminal-width)    shiftval;;
			--plain|-p|-pp|-ppp) :;;

			# Forward remaining.
			-*) {
				__bat_forward_args+=("$OPT")
				if [[ -n "$OPT_VAL" ]]; then
					__bat_forward_args+=("$OPT_VAL")
				fi
			};;

			*) __bat_forward_args+=("$OPT");;
		esac
	done
	
	# Insert batpipe arguments.
	if "$BATPIPE_INSIDE_LESS"; then
		__bat_batpipe_args+=(--decorations=always)
		__bat_batpipe_args+=(--terminal-width="$TERM_WIDTH")
		if "$BATPIPE_ENABLE_COLOR"; then
			__bat_batpipe_args+=(--color=always)
		fi
	fi
	
	if "$BATPIPE_INSIDE_BAT"; then
		__bat_batpipe_args+=(--decorations=never --color=never)
	fi
	
	# Execute the real bat.
	command "$EXECUTABLE_BAT" --paging=never "${__bat_batpipe_args[@]}" "${__bat_forward_args[@]}"
}

# -----------------------------------------------------------------------------
# Colors:
# -----------------------------------------------------------------------------

printc_init "[DEFINE]" << END
	C			\x1B[0m
	SUBPATH		\x1B[2;35m
	PATH		\x1B[0;35m
	HEADER		\x1B[0;36m
	SUBHEADER	\x1B[2;36m
END

# Enable color output if:
# - Parent is not less OR BATPIPE=color; AND
# - NO_COLOR is not defined.
#
# shellcheck disable=SC2034
if [[ "$BATPIPE_INSIDE_LESS" == "false" || "$BATPIPE" == "color" ]] && [[ -z "${NO_COLOR+x}" ]]; then
	BATPIPE_ENABLE_COLOR=true
	printc_init true
else
	BATPIPE_ENABLE_COLOR=false
	printc_init false
fi

# -----------------------------------------------------------------------------
# Main:
# -----------------------------------------------------------------------------

__CONFIG_DIR="$(config_dir batpipe)"
__TARGET_INSIDE=""
__TARGET_FILE="$(strip_trailing_slashes "$1")"

# Determine the target file by walking upwards from the specified path.
# This allows inner paths of archives to be used.
while ! [[ -e "$__TARGET_FILE" ]]; do
	__TARGET_INSIDE="$(basename -- "${__TARGET_FILE}")/${__TARGET_INSIDE}"
	__TARGET_FILE="$(dirname -- "${__TARGET_FILE}")"
done

# If the target file isn't actually a file, then the inner path should be appended.
if ! [[ -f "$__TARGET_FILE" ]]; then
	__TARGET_FILE="${__TARGET_FILE}/${__TARGET_INSIDE}"
	__TARGET_INSIDE=""
fi

# If an inner path exists or the target file isn't a directory, the target file should not have trailing slashes.
if [[ -n "$__TARGET_INSIDE" ]] || ! [[ -d "$__TARGET_FILE" ]]; then
	__TARGET_FILE="$(strip_trailing_slashes "$__TARGET_FILE")"	
fi

# Remove trailing slash of the inner target path.
__TARGET_INSIDE="$(strip_trailing_slashes "$__TARGET_INSIDE")"
__TARGET_BASENAME="$(basename -- "$__TARGET_FILE")"

# Stop bat from calling this recursively.
unset LESSOPEN
unset LESSCLOSE

# Load external viewers.
if [[ -d "${__CONFIG_DIR}/viewers.d" ]]; then
	unset LIB
	unset SELF

	shopt -o nullglob
	for viewer_script in "${__CONFIG_DIR}/viewers.d"/*; do
		source "${viewer_script}"
	done
	shopt -u nullglob
fi

# Try opening the file with the first viewer that supports it.
for viewer in "${BATPIPE_VIEWERS[@]}"; do
	if "viewer_${viewer}_supports" "$__TARGET_BASENAME" "$__TARGET_FILE" "$__TARGET_INSIDE" 1>&2; then
		"viewer_${viewer}_process" "$__TARGET_FILE" "$__TARGET_INSIDE"
		exit $?
	fi
done

# No supported viewer. Just pass it through.
exit 1
