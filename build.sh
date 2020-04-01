#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2019 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="$HERE/bin"
SRC="$HERE/src"
LIB="$HERE/lib"
source "${LIB}/print.sh"
source "${LIB}/opt.sh"
# -----------------------------------------------------------------------------
set -eo pipefail

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
	"$@"
	return $?
}

# Prints a build step message.
smsg() {
	case "$2" in
	"SKIP") printc "    %{YELLOW}      %{DIM}%s [skipped]%{CLEAR}\n" "$1" 1>&2 ;;
	*) printc "    %{YELLOW}      %s...%{CLEAR}\n" "$1" 1>&2 ;;
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
	cat "$1"
	smsg "Reading"
}

# Build step: preprocess
# Preprocesses the script.
#
# This will embed library scripts and replace the BAT variable.
#
# Input:
#     The original file contents.
#
# Output:
#      The processed file contents.
step_preprocess() {
	local line
	while IFS='' read -r line; do
		# Skip certain lines.
		[[ "$line" =~ ^LIB=.*$ ]] && continue

		# Replace the BAT variable with the build option.
		if [[ "$line" =~ ^BAT=.*$ ]]; then
			printf "BAT=%q\n" "$OPT_BAT"
			continue
		fi

		# Replace the DOCS_* variables.
		if [[ "$line" =~ ^DOCS_[A-Z]+=.*$ ]]; then
			local docvar
			docvar="$(cut -d'=' -f1 <<<"$line")"
			printf "%s=%q\n" "$docvar" "${!docvar}"
			continue
		fi

		# Embed library scripts.
		if [[ "$line" =~ ^[[:space:]]*source[[:space:]]+[\"\']\$\{?LIB\}/([a-z_-]+\.sh)[\"\'] ]]; then
			echo "# --- BEGIN LIBRARY FILE: ${BASH_REMATCH[1]} ---"
			{
				if [[ "$OPT_MINIFY" = "lib" ]]; then
					pp_strip_comments | pp_minify | pp_minify_unsafe
				else
					cat
				fi
			} <"$LIB/${BASH_REMATCH[1]}"
			echo "# --- END LIBRARY FILE ---"
			continue
		fi

		# Forward data.
		echo "$line"
	done

	smsg "Preprocessing"
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
	if [[ "$OPT_MINIFY" =~ ^all($|+.*) ]]; then
		cat
		smsg "Minifying" "SKIP"
		return 0
	fi

	printf "#!/usr/bin/env bash\n"
	pp_minify | pp_minify_unsafe
	smsg "Minifying"
}

# Build step: compress
# Compresses the input into a gzipped self-executable script.
#
# Input:
#     The original file contents.
#
# Output:
#     The compressed self-executable script.
step_compress() {
	if ! "$OPT_COMPRESS"; then
		cat
		smsg "Compressing" "SKIP"
		return 0
	fi

	local wrapper
	wrapper="$({
		printf '#!/usr/bin/env bash\n'
		printf "(exec -a \"\$0\" bash -c 'eval \"\$(cat <&3)\"' \"\$0\" \"\$@\" 3< <(dd bs=1 if=\"\$0\" skip=::: 2>/dev/null | gunzip)); exit \$?;\n"
	})"

	sed "s/:::/$(wc -c <<<"$wrapper" | bc)/" <<<"$wrapper"
	gzip
	smsg "Compressing"
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
	tee "$1"
	chmod +x "$1"
	smsg "Building"
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
		cat
		smsg "Installing" "SKIP"
		return 0
	fi

	tee "$1"
	chmod +x "$1"
	smsg "Installing"
}

# -----------------------------------------------------------------------------
# Preprocessor.

# Strips comments from a Bash source file.
pp_strip_comments() {
	sed '/^[[:space:]]*#.*$/d'
}

# Minify a Bash source file.
# https://github.com/mvdan/sh
pp_minify() {
	if [[ "$OPT_MINIFY" = "none" ]]; then
		cat
		return
	fi

	shfmt -mn
	return $?
}

# Minifies the output script (unsafely).
# Right now, this doesn't do anything.
# This should be applied after shfmt minification.
pp_minify_unsafe() {
	if ! [[ "$OPT_MINIFY" =~ ^.*+unsafe(+.*)*$ ]]; then
		cat
		return 0
	fi

	cat
}

# -----------------------------------------------------------------------------
# Options.
OPT_INSTALL=false
OPT_COMPRESS=false
OPT_VERIFY=true
OPT_MINIFY="lib"
OPT_PREFIX="/usr/local"
OPT_BAT="bat"

DOCS_URL="https://github.com/eth-p/bat-extras/blob/master/doc"
DOCS_MAINTAINER="eth-p <eth-p@hidden.email>"

while shiftopt; do
	case "$OPT" in
	--install) OPT_INSTALL=true ;;
	--compress) OPT_COMPRESS=true ;;
	--prefix)
		shiftval
		OPT_PREFIX="$OPT_VAL"
		;;
	--alternate-executable)
		shiftval
		OPT_BAT="$OPT_VAL"
		;;
	--minify)
		shiftval
		OPT_MINIFY="$OPT_VAL"
		;;
	--no-verify)
		shiftval
		OPT_VERIFY=false
		;;
	--docs:url)
		shiftval
		DOCS_URL="$OPT_VAL"
		;;
	--docs:maintainer)
		shiftval
		DOCS_MAINTAINER="$OPT_VAL"
		;;

	*)
		printc "%{RED}%s: unknown option '%s'%{CLEAR}" "$PROGRAM" "$OPT"
		exit 1
		;;
	esac
done

if [[ "$OPT_BAT" != "bat" ]]; then
	printc "%{YELLOW}Building executable scripts with an alternate bat executable at %{CLEAR}%s%{YELLOW}.%{CLEAR}\n" "$OPT_BAT" 1>&2
	if ! command -v "$OPT_BAT"; then
		printc "%{YELLOW}WARNING: Bash cannot execute the specified file.\n" 1>&2
		printc "%{YELLOW}         The finished scripts may not run properly.%{CLEAR}\n" 1>&2
	fi
	printc "\n" 1>&2
fi

if [[ "$OPT_INSTALL" = true ]]; then
	printc "%{YELLOW}Installing to %{MAGENTA}%s%{YELLOW}.%{CLEAR}\n" "$OPT_PREFIX" 1>&2
else
	printc "%{YELLOW}This will not install the script.%{CLEAR}\n" 1>&2
	printc "%{YELLOW}Use %{BLUE}--install%{YELLOW} for a global install.%{CLEAR}\n\n" 1>&2
fi

# -----------------------------------------------------------------------------
# Check for resources.

[[ -d "$BIN" ]] || mkdir "$BIN"

if [[ "$OPT_MINIFY" != "none" ]] && ! command -v shfmt &>/dev/null; then
	printc "%{RED}Warning: cannot find shfmt. Unable to minify scripts.%{CLEAR}\n"
	OPT_MINIFY=none
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
	((file_i++)) || true

	filename="$(basename "$file" .sh)"

	printc "    %{YELLOW}[%s/%s] %{MAGENTA}%s%{CLEAR}\n" "$file_i" "$file_n" "$file" 1>&2
	step_read "$file" |
		next step_preprocess |
		next step_minify |
		next step_compress |
		next step_write "${BIN}/${filename}" |
		next step_write_install "${OPT_PREFIX}/bin/${filename}" |
		cat >/dev/null
done

# -----------------------------------------------------------------------------
# Verify files by running the tests.

if "$OPT_VERIFY"; then
	printc "\n%{YELLOW}Verifying scripts...%{CLEAR}\n" 1>&2
	"${HERE}/test.sh" --compiled
	exit $?
fi
