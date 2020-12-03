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
MAN="$HERE/man"
MAN_SRC="$HERE/doc"
LIB="$HERE/lib"
source "${LIB}/print.sh"
source "${LIB}/opt.sh"
source "${LIB}/constants.sh"
# -----------------------------------------------------------------------------
set -eo pipefail
exec 3>&1

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
	"SKIP") printc_msg "    %{YELLOW}      %{DIM}%s [skipped]%{CLEAR}\n" "$1" ;;
	*)      printc_msg "    %{YELLOW}      %s...%{CLEAR}\n" "$1" ;;
	esac
}

# Prints a message to STDOUT (via FD 3).
# Works the same as printc.
printc_msg() {
	printc "$@" 1>&3
}

# Prints a message to STDERR.
# Works the same as printc.
printc_err() {
	printc "$@" 1>&2
}

# Escapes a sed pattern.
# Arguments:
#     1  -- The pattern.
#
# Output:
#     The escaped string.
sed_escape() {
	sed 's/\([][\\\/\^\$\*\.\-]\)/\\\1/g' <<< "$1"
}

# Checks if the output scripts will be minified.
# Arguments:
#    1  "all"    -- All scripts will be minified.
#       "any"    -- Any scripts will be minified.
#       "lib"    -- Library scripts will be minified.
#       "unsafe" -- Unsafe minifications will be applied.
will_minify() {
	case "$1" in
	all)
		[[ "$OPT_MINIFY" =~ ^all($|\+.*) ]]
		return $? ;;
	unsafe)
		[[ "$OPT_MINIFY" =~ ^.*+unsafe(\+.*)*$ ]]
		return $? ;;
	lib)
		[[ "$OPT_MINIFY" =~ ^lib($|\+.*) ]]
		return $? ;;
	any|"")
		[[ "$OPT_MINIFY" != "none" ]]
		return $? ;;
	none)
		! will_minify any
		return $? ;;
	esac
	return 1
}

# Generates the banner for the output files.
#
# Output:
#    The contents of banner.txt
generate_banner() {
	local step="$1"
	if ! "$OPT_BANNER"; then
		return 0
	fi

	# Don't run it unless the comments are removed or hidden.
	if ! { will_minify all || "$OPT_COMPRESS"; }; then
		return 0
	fi

	# Only run it in the compression step if both minifying and compressing.
	if will_minify all && "$OPT_COMPRESS" && [[ "$step" != "step_compress" ]]; then
		return 0
	fi

	# Write the banner.
	bat "${HERE}/banner.txt"
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
# This will embed library scripts and inline constants.
#
# Input:
#     The original file contents.
#
# Output:
#      The processed file contents.
step_preprocess() {
	local line
	local docvar
	pp_consolidate | while IFS='' read -r line; do
		# Skip certain lines.
		[[ "$line" =~ ^LIB=.*$ ]] && continue
		[[ "$line" =~ ^[[:space:]]*source[[:space:]]+[\"\']\$\{?LIB\}/(constants\.sh)[\"\'] ]] && continue

		# Forward data.
		echo "$line"
	done | pp_inline_constants

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
	if ! will_minify all; then
		cat
		smsg "Minifying" "SKIP"
		return 0
	fi

	printf "#!/usr/bin/env bash\n"
	generate_banner step_minify
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
		generate_banner step_compress
		printf "(exec -a \"\$0\" bash -c 'eval \"\$(cat <&3)\"' \"\$0\" \"\$@\" 3< <(dd bs=1 if=\"\$0\" skip=::: 2>/dev/null | gunzip)); exit \$?;\n"
	})"

	echo "${wrapper/:::/$(wc -c <<<"$wrapper" | sed 's/^[[:space:]]*//')}"
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
# Preprocessor:
# -----------------------------------------------------------------------------

# Consolidates all scripts into a single file.
# This follows all `source "${LIB}/..."` files and embeds them into the script.
pp_consolidate() {
	PP_CONSOLIDATE_PROCESSED=()
	pp_consolidate__do 0
}

pp_consolidate__do() {
	local depth="$1"
	local indent="$(printf "%-${depth}s" | tr ' ' $'\t')"

	local line
	while IFS='' read -r line; do
		# Embed library scripts.
		if [[ "$line" =~ ^[[:space:]]*source[[:space:]]+[\"\']\$\{?LIB\}/([a-z_-]+\.sh)[\"\'] ]]; then
			local script_name="${BASH_REMATCH[1]}"
			local script="$LIB/$script_name"

			# Skip if it's the constants library.
			[[ "$script_name" = "constants.sh" ]] && continue

			# Skip if it's already embedded.
			local other
			for other in "${PP_CONSOLIDATE_PROCESSED[@]}"; do
				[[ "$script" = "$other" ]] && continue 2
			done
			PP_CONSOLIDATE_PROCESSED+=("$script")

			# Embed the script.
			echo "${indent}# --- BEGIN LIBRARY FILE: ${BASH_REMATCH[1]} ---"
			{
				if will_minify lib; then
					pp_strip_comments | pp_minify | pp_minify_unsafe
				else
					pp_strip_copyright | pp_strip_separators
				fi
			} < <(pp_consolidate__do "$((depth + 1))" < "$script") | sed "s/^/${indent}/"
			echo "${indent}# --- END LIBRARY FILE ---"
			continue
		fi

		# Forward data.
		echo "$line"
	done
}

# Inlines constants:
# EXECUTABLE_*
# PROGRAM_*
pp_inline_constants() {
	local constants=("PROGRAM")

	# Determine the PROGRAM_ constants.
	local nf_constants="$( ( set -o posix ; set) | grep '^\(PROGRAM_\|EXECUTABLE_\)' | cut -d'=' -f1)"
	local line
	while read -r line; do
		constants+=("$line")
	done <<< "$nf_constants"

	# Generate a sed replace for the constants.
	local constants_pattern=''
	local constant_name
	local constant_value
	for constant_name in "${constants[@]}"; do
		constant_value="$(sed_escape "${!constant_name}")"
		constant_name="$(sed_escape "$constant_name")"
		constant_sed="s/\\\$${constant_name}\([^A-Za-z0-9_]\)/${constant_value}\1/; s/\\\${${constant_name}}/${constant_value}/g;"
		constants_pattern="${constants_pattern}${constant_sed}"
	done

	sed "${constants_pattern}"
}


# Strips comments from a Bash source file.
pp_strip_comments() {
	sed '/^[[:space:]]*#.*$/d'
}

# Strips copyright comments from the start of a Bash source file.
pp_strip_copyright() {
	awk '/^#/ {if(!p){ next }} { p=1; print $0 }'
}

# Strips separator comments from the start of a Bash source file.
pp_strip_separators() {
	awk '/^#\s*-{5,}/ { next; } {print $0}'
}

# Minify a Bash source file.
# https://github.com/mvdan/sh
pp_minify() {
	if will_minify none; then
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
	if ! will_minify unsafe; then
		cat
		return 0
	fi

	cat
}

# -----------------------------------------------------------------------------
# Options:
# -----------------------------------------------------------------------------
OPT_INSTALL=false
OPT_COMPRESS=false
OPT_VERIFY=true
OPT_BANNER=true
OPT_MANUALS=true
OPT_INLINE=true
OPT_MINIFY="lib"
OPT_PREFIX="/usr/local"
OPT_BAT="$(basename "$EXECUTABLE_BAT")"

DOCS_URL="https://github.com/eth-p/bat-extras/blob/master/doc"
DOCS_MAINTAINER="eth-p <eth-p@hidden.email>"

while shiftopt; do
	# shellcheck disable=SC2034
	case "$OPT" in
	--install)                        OPT_INSTALL=true ;;
	--compress)                       OPT_COMPRESS=true ;;
	--manuals)                        OPT_MANUALS=true ;;
	--no-manuals)                     OPT_MANUALS=false ;;
	--no-verify)                      OPT_VERIFY=false ;;
	--no-banner)                      OPT_BANNER=false ;;
	--no-inline)                      OPT_INLINE=false ;;
	--prefix)               shiftval; OPT_PREFIX="$OPT_VAL" ;;
	--alternate-executable) shiftval; OPT_BAT="$OPT_VAL" ;;
	--minify)		        shiftval; OPT_MINIFY="$OPT_VAL" ;;

	*)
		printc_err "%{RED}%s: unknown option '%s'%{CLEAR}" "$PROGRAM" "$OPT"
		exit 1
		;;
	esac
done

if [[ "$OPT_BAT" != "bat" ]]; then
	printc_msg "%{YELLOW}Building executable scripts with an alternate bat executable %{CLEAR}%s%{YELLOW}.%{CLEAR}\n" "$OPT_BAT"
	if ! command -v "$OPT_BAT" &>/dev/null; then
		printc_err "%{YELLOW}WARNING: Bash cannot execute the specified file.\n"
		printc_err "%{YELLOW}         The finished scripts may not run properly.%{CLEAR}\n"
	fi

	# shellcheck disable=SC2034
	EXECUTABLE_BAT="$OPT_BAT"
	printc_msg "\n"
fi

if [[ "$OPT_INSTALL" = true ]]; then
	printc_msg "%{YELLOW}Installing to %{MAGENTA}%s%{YELLOW}.%{CLEAR}\n" "$OPT_PREFIX"
else
	printc_msg "%{YELLOW}This will not install the script.%{CLEAR}\n"
	printc_msg "%{YELLOW}Use %{BLUE}--install%{YELLOW} for a global install.%{CLEAR}\n\n"
fi

if [[ "$OPT_INLINE" = false ]]; then
	# Prevent full executable paths from being inlined.
	while read -r exec; do
		declare "$exec=$(basename "${!exec}")"
	done < <(set | grep '^EXECUTABLE' | cut -d'=' -f1)
fi

# -----------------------------------------------------------------------------
# Check for resources.

if ! will_minify none && ! command -v shfmt &>/dev/null; then
	printc_err "%{RED}Warning: cannot find shfmt. Unable to minify scripts.%{CLEAR}\n"
	OPT_MINIFY=none
fi

# -----------------------------------------------------------------------------
# Check target directories exist.

[[ -d "$BIN" ]] || mkdir -p "$BIN"

if "$OPT_INSTALL"; then
	[[ -d "${OPT_PREFIX}/bin" ]] || mkdir -p "${OPT_PREFIX}/bin"
fi

# -----------------------------------------------------------------------------
# Find files.

SOURCES=()

printc_msg "%{YELLOW}Preparing scripts...%{CLEAR}\n"
for file in "$SRC"/*.sh; do
	SOURCES+=("$file")
done

# -----------------------------------------------------------------------------
# Build manuals.

if "$OPT_MANUALS"; then
	source "${HERE}/mdroff.sh"
	if ! [[ -d "$MAN" ]]; then
		mkdir -p "$MAN"
	fi
	
	printc_msg "%{YELLOW}Building manuals...%{CLEAR}\n"
	for source in "${SOURCES[@]}"; do
		name="$(basename "$source" .sh)"
		doc="${MAN_SRC}/${name}.md"
		docout="${MAN}/${name}.1"
		if ! [[ -f "$doc" ]]; then
			continue
		fi
		
		printc_msg "    %{YELLOW}      %{MAGENTA}%s%{CLEAR}\n" "$(basename "$docout")"
		(mdroff < "$doc" > "${MAN}/${name}.1")
	done
	printc_msg "\n"
fi

# -----------------------------------------------------------------------------
# Build files.

printc_msg "%{YELLOW}Building scripts...%{CLEAR}\n"
file_i=0
file_n="${#SOURCES[@]}"
for file in "${SOURCES[@]}"; do
	((file_i++)) || true

	filename="$(basename "$file" .sh)"
	PROGRAM="$filename"
	PROGRAM_VERSION="$(<"${HERE}/version.txt")"

	printc_msg "    %{YELLOW}[%s/%s] %{MAGENTA}%s%{CLEAR}\n" "$file_i" "$file_n" "$file"
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
	printc_msg "\n%{YELLOW}Verifying scripts...%{CLEAR}\n"

	# Run the tests.
	FAIL=0
	SKIP=0
	while read -r action data1 data2 splat; do
		[[ "$action" == "result" ]] || continue
		case "$data2" in
			fail)
				printc_err "\x1B[G\x1B[K%s failed.\n" "$data1"
				((FAIL++)) || true
				;;

			skip)
				printc_msg "\x1B[G\x1B[K%s skipped.\n" "$data1"
				((SKIP++)) || true
				;;

			*)
				printc_msg "\x1B[G\x1B[K%s" "$data1"
				;;
		esac
	done < <("${HERE}/test.sh" --compiled --porcelain --jobs=8)

	# Print the overall result.
	printc_msg "\x1B[G\x1B[K"

	if [[ "$FAIL" -ne 0 ]]; then
		printc_err "%{RED}%s\n" "One or more tests failed."
		printc_msg "\x1B[A\x1B[G\x1B[K%{RED}%s\n" "One or more tests failed."
		printc_err "%{RED}%s%{CLEAR}\n" "Run ./test.sh for more detailed information."
		exit 1
	fi

	if [[ "$SKIP" -gt 0 ]]; then
		printc_err "%{CYAN}One or more tests were skipped.\n"
		printc_err "Run ./test.sh for more detailed information.%{CLEAR}\n"
	fi

	printc_msg "%{YELLOW}Verified successfully.%{CLEAR}\n"
fi
