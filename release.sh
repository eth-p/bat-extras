#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2019 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATE="$(date +%Y%m%d)"
LIB="$HERE/lib"
source "${LIB}/print.sh"
source "${LIB}/opt.sh"
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# Options.
OPT_TAG="v${DATE}"
OPT_ARTIFACT="bat-extras-${DATE}.zip"
OPT_SKIP_TAG=true
OPT_BIN_DIR="$HERE/bin"
OPT_DOC_DIR="$HERE/doc"

while shiftopt; do
	case "$OPT" in
	--tag) OPT_SKIP_TAG=false ;;

	*)
		printc "%{RED}%s: unknown option '%s'%{CLEAR}" "$PROGRAM" "$OPT"
		exit 1
		;;
	esac
done

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
