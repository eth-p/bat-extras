#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2019 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATE="$(date +%Y%m%d)"
VERSION="$(<"${HERE}/version.txt")"
VERSION_EXPECTED="$(date +%Y.%m.%d)"
LIB="$HERE/lib"
SRC="$HERE/src"
source "${LIB}/print.sh"
source "${LIB}/opt.sh"
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Options.
OPT_ARTIFACT="bat-extras-${DATE}.zip"
OPT_SINCE=
OPT_BIN_DIR="$HERE/bin"
OPT_DOC_DIR="$HERE/doc"

while shiftopt; do
	case "$OPT" in
	--since)
		shiftval
		OPT_SINCE="$OPT_VAL"
		if ! git rev-parse "$OPT_SINCE" &>/dev/null; then
			printc "%{RED}%s: unknown commit or tag for '%s'\n" "$PROGRAM" "$OPT"
			exit 1
		fi
		;;

	*)
		printc "%{RED}%s: unknown option '%s'%{CLEAR}" "$PROGRAM" "$OPT"
		exit 1
		;;
	esac
done

# -----------------------------------------------------------------------------
# Verify the version matches today's date.
if [[ "$VERSION" != "$VERSION_EXPECTED" ]]; then
	printc "%{RED}The expected version does not match %{WHITE}version.txt%{RED}!%{CLEAR}\n"
	printc "%{RED}Expected: %{YELLOW}%s%{CLEAR}\n" "$VERSION_EXPECTED"
	printc "%{RED}Actual:   %{YELLOW}%s%{CLEAR}\n" "$VERSION"
	exit 1
fi

# -----------------------------------------------------------------------------
# Build files.

# Clean the old bin files.
# Make sure it's not trying to delete /bin first, though.
if [[ "$OPT_BIN_DIR" != "/bin" ]]; then
	rm -rf "$OPT_BIN_DIR"
fi

# Generate the new bin files.
printc "%{YELLOW}Building scripts...%{CLEAR}\n"
"$HERE/build.sh" --minify=all &>/dev/null || {
	printc "%{RED}FAILED TO BUILD SCRIPTS.%{CLEAR}\n"
	printc "%{RED}CAN NOT PROCEED WITH RELEASE.%{CLEAR}\n"
	exit 1
}

# -----------------------------------------------------------------------------
# Tag release.

if ! "$OPT_SKIP_TAG"; then
	printc "%{YELLOW}Tagging release...%{CLEAR}\n"
	git tag "$OPT_TAG"
fi

# -----------------------------------------------------------------------------
# Build package.

printc "%{YELLOW}Packaging artifacts...%{CLEAR}\n"
zip -r "$OPT_ARTIFACT" \
	"$OPT_BIN_DIR" \
	"$OPT_DOC_DIR"

printc "%{YELLOW}Package created as %{BLUE}%s%{YELLOW}.%{CLEAR}\n" "$OPT_ARTIFACT"

# -----------------------------------------------------------------------------
# Print template description package.

printc "%{YELLOW}Release description:%{CLEAR}\n"

# Get the commit hash.
COMMIT="$(git rev-parse HEAD)"
COMMIT_URL="https://github.com/eth-p/bat-extras/tree/${COMMIT}"

# Get the release date string.
DATE_DAY="$(date +%e | sed 's/ //')"
DATE_SUFFIX=""
case "$DATE_DAY" in
	11|12|13) DATE_SUFFIX="th" ;;
	*1) DATE_SUFFIX="st" ;;
	*2) DATE_SUFFIX="nd" ;;
	*3) DATE_SUFFIX="rd" ;;
	*)  DATE_SUFFIX="th" ;;
esac
DATE_STR="$(date +'%B') ${DATE_DAY}${DATE_SUFFIX}, $(date +'%Y')"

# Get the script names.
script_links=()
script_names=()
for script in "$SRC"/*.sh; do
	script_name="$(basename "$script" .sh)"
	script_names+=("$script_name")
	script_links+=("[\`${script_name}\`](https://github.com/eth-p/bat-extras/blob/${COMMIT}/doc/${script_name}.md)")
done

SCRIPTS="$(printf "%s, " "${script_links[@]:0:$((${#script_links[@]}-1))}")"
SCRIPTS="${SCRIPTS}and ${script_links[$((${#script_links[@]}-1))]}"

# Get the changelog.
CHANGELOG_DEV=''
CHANGELOG=''
if [[ -n "$OPT_SINCE" ]]; then
	ref="$(git rev-parse HEAD)"
	end="$(git rev-parse "$OPT_SINCE")"
	while [[ "$ref" != "$end" ]]; do
		is_developer=false
		ref_message="$(git show -s --format=%s "$ref")"
		ref="$(git rev-parse "${ref}~1")"

		if [[ "$ref_message" =~ ^([a-z\-]+):[[:space:]]*(.*)$ ]]; then
			affected_module="${BASH_REMATCH[1]}"

			# Make module names consistent.
			case "$affected_module" in
				dev|lib) affected_module="developer" ;;
				tests) affected_module="test" ;;
				doc) affected_module="docs" ;;
			esac

			# Switch to the correct changelog.
			case "$affected_module" in
				test|developer|ci) is_developer=true ;;
			esac

			# Edit the ref message if it's a script change.
			for script_name in "${script_names[@]}"; do
				if [[ "$affected_module" = "$script_name" ]]; then
					ref_message="\`${affected_module}\`: ${BASH_REMATCH[2]}"
					break
				fi
			done
		fi

		# Append to changelog.
		if "$is_developer"; then
			CHANGELOG_DEV="$CHANGELOG_DEV"$'\n'" - ${ref_message}"
		else
			CHANGELOG="$CHANGELOG"$'\n'" - ${ref_message}"
		fi
	done
fi

# Print the template.
sed '/\\$/{N;s/\\\n//;s/\n//p;}' <<-EOF
This contains the latest versions of $SCRIPTS as of commit [$(git rev-parse --short HEAD)]($COMMIT_URL) (${DATE_STR}).

**This is provided as a convenience only.**
I would still recommend following the installation instructions in \
[the README](https://github.com/eth-p/bat-extras#installation-) for the most up-to-date versions.

### Changes
$CHANGELOG

### Developer
<details>
<div markdown="1">

$CHANGELOG_DEV

</div>
</details>
EOF
