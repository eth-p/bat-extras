#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2019 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DL="$HERE/.download"
BIN="$HERE/bin"
SRC="$HERE/src"
LIB="$HERE/lib"
source "${LIB}/print.sh"
source "${LIB}/opt.sh"
# -----------------------------------------------------------------------------

# Runs the next build step.
#
# Arguments:
#     1  -- The build step function name.
#     @  -- The function arguments.
#
# Input:
#     The unprocessed file data.
#
# Output:
#     The processed file data.
next() {
	local buffer="$(cat)"
	"$@" <<< "$buffer"
	return $?
}

# Prints a build step message.
smsg() {
	case "$2" in
		"SKIP") printc "    %{YELLOW}      %{DIM}%s [skipped]%{CLEAR}\n" "$1" 1>&2;;
		*)      printc "    %{YELLOW}      %s...%{CLEAR}\n" "$1" 1>&2;;
	esac
}

# Build step: read
# Reads the file from its source.
#
# Arguments:
#     1  -- The source file.
#
# Output:
#     The file contents.
step_read() {
	smsg "Reading"
	cat "$1"
}

# Build step: preprocess
# Preprocesses the script.
#
# This will embed library scripts.
#
# Input:
#     The original file contents.
# 
# Output:
#      The processed file contents.
step_preprocess() {
	smsg "Preprocessing"

	local line
	while IFS='' read -r line; do
		# Skip certain lines.
		[[ "$line" =~ ^LIB=.*$ ]] && continue

		# Embed library scripts.
		if [[ "$line" =~ ^[[:space:]]*source[[:space:]]+[\"\']\$\{?LIB\}/([a-z-]+\.sh)[\"\'] ]]; then
			echo "# --- BEGIN LIBRARY FILE: ${BASH_REMATCH[1]} ---"
			cat "$LIB/${BASH_REMATCH[1]}" | {
				if [[ "$OPT_MINIFY" = "lib" ]]; then
					pp_strip_comments | pp_minify
				else
					cat
				fi
			}
			echo "# --- END LIBRARY FILE ---"
			continue
		fi

		# Forward data.
		echo "$line"
	done
}

# Build step: minify
# Minifies the output script.
#
# Input:
#     The original file contents.
#
# Output:
#     The minified file contents.
step_minify() {
	if [[ "$OPT_MINIFY" != "all" ]]; then
		smsg "Minifying" "SKIP"
		cat
		return 0
	fi

	smsg "Minifying"
	printf "#!/usr/bin/env bash\n"
	pp_minify
}

# Build step: write
# Writes the output script to a file.
#
# Arguments:
#     1  -- The file to write to.
#
# Input:
#     The file contents.
#
# Output:
#     The file contents.
step_write() {
	smsg "Building"
	tee "$1"
	chmod +x "$1"
}

# Build step: write
# Optionally writes the output script to a file.
#
# Arguments:
#     1  -- The file to write to.
#
# Input:
#     The file contents.
#
# Output:
#     The file contents.

step_write_install() {
	if [[ "$OPT_INSTALL" != true ]]; then
		smsg "Installing" "SKIP"
		cat
		return 0
	fi

	smsg "Installing"
	tee "$1"
	chmod +x "$1"
}

# -----------------------------------------------------------------------------
# Preprocessor.

# Strips comments from a Bash source file.
pp_strip_comments() {
	sed '/^[[:space:]]*#.*$/d'
}

# Minify a Bash source file.
# https://github.com/precious/bash_minifier
pp_minify() {
	local python="python"
	if command -v python2 &>/dev/null; then
		python="python2"
	fi

	"$python" "$DL/minifier.py"
	printf "\n"
}

# -----------------------------------------------------------------------------
# Options.
OPT_INSTALL=false
OPT_MINIFY="lib"
OPT_PREFIX="/usr/local"

while shiftopt; do
	case "$OPT" in
		--install)   OPT_INSTALL=true;;
		--prefix)    shiftval; OPT_PREFIX="$OPT_VAL";;
		--minify)    shiftval; OPT_MINIFY="$OPT_VAL";;
		
		*)         printc "%{RED}%s: unknown option '%s'%{CLEAR}" "$PROGRAM" "$OPT";
		           exit 1;;
	esac
done

if [[ "$OPT_INSTALL" = true ]]; then
	printc "%{YELLOW}Installing to %{MAGENTA}%s%{YELLOW}.%{CLEAR}\n" "$OPT_PREFIX" 1>&2
else
	printc "%{YELLOW}This will not install the script.%{CLEAR}\n" 1>&2
	printc "%{YELLOW}Use %{BLUE}--install%{YELLOW} for a global install.%{CLEAR}\n\n" 1>&2
fi

# -----------------------------------------------------------------------------
# Download resources.

[[ -d "$DL" ]] || mkdir "$DL"
[[ -d "$BIN" ]] || mkdir "$BIN"

if [[ "$OPT_MINIFY" != "none" ]] && ! [[ -f "$DL/minifier.py" ]]; then
	printc "%{YELLOW}Downloading %{BLUE}https://github.com/precious/bash_minifier%{YELLOW}...%{CLEAR}\n" 1>&2
	curl -sL "https://gitcdn.xyz/repo/precious/bash_minifier/master/minifier.py" > "$DL/minifier.py"
fi

# -----------------------------------------------------------------------------
# Find files.

SOURCES=()

printc "%{YELLOW}Preparing scripts...%{CLEAR}\n" 1>&2
for file in "$SRC"/*.sh; do
	SOURCES+=("$file")
done

# -----------------------------------------------------------------------------
# Build files.


printc "%{YELLOW}Building scripts...%{CLEAR}\n" 1>&2
file_i=0
file_n="${#SOURCES[@]}"
for file in "${SOURCES[@]}"; do
	((file_i++))

	filename="$(basename "$file" .sh)"

	printc "    %{YELLOW}[%s/%s] %{MAGENTA}%s%{CLEAR}\n" "$file_i" "$file_n" "$file" 1>&2
	step_read "$file" |\
		next step_preprocess |\
		next step_minify |\
		next step_write "${BIN}/${filename}" |\
		next step_write_install "${OPT_PREFIX}/bin/${filename}" |\
		cat >/dev/null
done


