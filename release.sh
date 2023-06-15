#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2019-2023 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/build.sh"

# -----------------------------------------------------------------------------
# Release-as-a-Library Functions:
# -----------------------------------------------------------------------------

# Prints the path to the git workspace.
if ! batextras:is_function_defined ::get_git_workspace; then
	batextras:get_git_workspace() {
		batextras:lazy_done "${FUNCNAME[0]}" \
			"$(batextras:get_project_directory)"
	}
fi

# Prints the commit of the latest-tagged version of bat-extras.
if ! batextras:is_function_defined ::get_current_commit; then
	batextras:get_current_commit() {
		batextras:lazy_done "${FUNCNAME[0]}" \
			"$(batextras:git rev-parse HEAD)"
	}
fi

# Prints the commit of the latest-tagged version of bat-extras.
if ! batextras:is_function_defined ::get_previous_tag_commit; then
	batextras:get_previous_tag_commit() {
		local latest_tag
		local before_latest_tag
		{
			read -r latest_tag
			read -r before_latest_tag
		} < <(batextras:git rev-list --tags --max-count=2)

		# If the latest commit is a tag, go to the one before that.
		if [[ "$(batextras:get_current_commit)" = "$latest_tag" ]]; then
			latest_tag="${before_latest_tag}"
		fi

		batextras:lazy_done "${FUNCNAME[0]}" "$latest_tag"
	}
fi

# Prints the ref name of the latest-tagged version of bat-extras.
if ! batextras:is_function_defined ::get_previous_tag_name; then
	batextras:get_previous_tag_name() {
		batextras:lazy_done "${FUNCNAME[0]}" \
			"$(batextras:git describe --tags --abbrev=0 "$(batextras:get_previous_tag_commit)")"
	}
fi

# Returns the suffix for a day of the month.
#
# Arguments:
#     1  -- The day number.
#
# Output:
#     The suffix.
batextras:day_suffix() {
	case "$1" in
		11 | 12 | 13) echo "th" ;;
		*1) echo "st" ;;
		*2) echo "nd" ;;
		*3) echo "rd" ;;
		*)  echo "th" ;;
	esac
}

# Runs `git` within the project directory.
#
# This takes the same arguments as git (with the exception of `-C`), and
# does exactly what `git` would normally do.
batextras:git() {
	git -C "$(batextras:get_git_workspace)" "$@"
	return $?
}

# Creates the zipball for release.
# YOU MUST BUILD THE PROJECT FIRST!
#
# Arguments:
#     1  -- The absolute path to the output zip file.
#
# Stderr:
#     Messages.
batextras:create_package() {
	local artifact="$1"
	local bin_dir man_dir doc_dir
	bin_dir="$(batextras:get_output_bin_directory)"
	man_dir="$(batextras:get_output_man_directory)"
	doc_dir="$(batextras:get_docs_directory)"

	(
		# Remove the old zipball, if one exists.
		if [[ -f "$artifact" ]]; then
			rm "$artifact" || return $?
		fi

		# Add the bin directory.
		cd "$(dirname -- "$bin_dir")" || return $?
		zip -r "$artifact" "$(basename -- "$bin_dir")"

		# Add the doc directory.
		cd "$(dirname -- "$doc_dir")" || return $?
		zip -ru "$artifact" "$(basename -- "$doc_dir")"

		# Add the man directory.
		if [[ -d "$man_dir" ]]; then
			cd "$(dirname -- "$man_dir")" || return $?
			zip -ru "$artifact" "$(basename -- "$man_dir")"
		fi
	) 1>&2
}

# Generates a Markdown changelog for all changes between two commits.
#
# Arguments:
#     1  -- The first commit, exclusive.
#     2  -- The second commit, inclusive.
#     3  -- A filter in regex.
#
# Output:
#     The changelog.
batextras:generate_changelog() {
	local start_commit="$1"
	local end_commit="$2"
	local filter="${3}"

	# Generate sed replacement patterns.
	local script_links=()
	local script_names=()
	local script script_name
	while read -r script; do
		script_name="$(basename "$script" .sh)"
		script_names+=("$script_name")
	done < <(batextras:get_source_paths)

	local script_pattern
	script_pattern="$(printf 's/\\(%s\\)/`\\1`/;' "${script_names[@]}")"

	# Generate the changelog.
	local changelog=''
	local commit
	local affected_module
	local commit_message
	while read -r commit; do
		commit_message="$(batextras:git show -s --format=%s "$commit")"

		if ! [[ "$commit_message" =~ ^([a-z-]+):[[:space:]]*(.*)$ ]]; then
			continue
		fi

		affected_module="${BASH_REMATCH[1]}"

		# Make module names consistent.
		case "$affected_module" in
			dev | lib | mdroff) affected_module="developer" ;;
			tests) affected_module="test" ;;
			doc) affected_module="docs" ;;
		esac

		# Append to changelog.
		if [[ "$affected_module" =~ ^($filter)$ ]]; then
			changelog="$changelog"$'\n'" - ${commit_message}"
		fi
	done < <(batextras:git rev-list "${start_commit}..${end_commit}")

	# Print the changelog.
	changelog="$(sed "$script_pattern" <<< "$changelog")"
	printf "%s\n" "${changelog:1}"
	return 0
}

# Generates the Markdown release notes.
#
# Arguments:
#     1  -- The oldest commit, exclusive.
#     2  -- The newest commit, inclusive.
#
# Output:
#     The changelog.
batextras:generate_release_notes() {
	local commit_oldest="$1"
	local commit_newest="$2"
	local commit_newest_url="https://github.com/eth-p/bat-extras/tree/${commit_newest}"
	local date_str

	# Get the commit date.
	local date_year date_month date_day date_month_text date_day_suffix
	read -r date_year date_month date_day date_month_text \
		< <(batextras:git show -s --format="%cd" --date="format:%Y %m %d %B" "$commit_newest")

	date_day_suffix="$(batextras:day_suffix "$date_day")"
	date_str="${date_month_text} ${date_day}${date_day_suffix}, ${date_year}"

	# For each built script, we want to:
	#   - Get the name of the script.
	#   - Get a link to the documentation.
	#   - Add it to the filter for non-developer items.
	local script_name script_names script_links script_filters script_list_markdown
	script_links=()
	script_names=()
	script_filters=''

	while read -r script; do
		script_name="$(basename "$script" .sh)"
		script_names+=("$script_name")
		script_links+=("[\`${script_name}\`](https://github.com/eth-p/bat-extras/blob/${commit_newest}/doc/${script_name}.md)")
		script_filters="${script_filters}|$(printf "%q" "$script_name")"
	done < <(batextras:get_source_paths)

	script_filters="${script_filters:1}" # Remove the leading "|"
	script_list_markdown="$(printf "%s, " "${script_links[@]:0:$((${#script_links[@]} - 1))}")"
	script_list_markdown="${script_list_markdown}and ${script_links[$((${#script_links[@]} - 1))]}"

	# Get the changelog.
	local changelog changelog_dev
	changelog="$(batextras:generate_changelog "$commit_oldest" "$commit_newest" "$script_filters")"
	changelog_dev="$(batextras:generate_changelog "$commit_oldest" "$commit_newest" "test|developer|ci|build")"

	# Print the template.
	{ sed '/\\$/{N;s/\\\n//;s/\n//p;}'; } <<- EOF
		This contains the latest versions of ${script_list_markdown} as of commit [${commit_newest}](${commit_newest_url}) (${date_str}).

		**This is provided as a convenience only.**
		I would still recommend following the installation instructions in [the README](https://github.com/eth-p/bat-extras#installation-) for the most up-to-date versions.

		### Changes
		${changelog}

		### Developer
		<details>
		<div markdown="1">

		${changelog_dev}

		</div>
		</details>
	EOF

}

# -----------------------------------------------------------------------------
# Main:
# Only run everything past this point if the script is not sourced.
# -----------------------------------------------------------------------------
(return 0 2>/dev/null) && return 0

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATE="$(date +%Y%m%d)"
VERSION="$(< "${HERE}/version.txt")"
VERSION_EXPECTED="$(date +%Y.%m.%d)"
LIB="$HERE/lib"
SRC="$HERE/src"
source "${LIB}/print.sh"
source "${LIB}/opt.sh"
# -----------------------------------------------------------------------------
set -euo pipefail

# -----------------------------------------------------------------------------
# Options.
OPT_ARTIFACT="bat-extras-${DATE}.zip"
OPT_SINCE=
OPT_BAD_IDEA=false
OPT_BIN_DIR="$(batextras:get_output_bin_directory)"
OPT_DOC_DIR="$(batextras:get_docs_directory)"
OPT_MAN_DIR="$(batextras:get_output_man_directory)"

while shiftopt; do
	case "$OPT" in
		--since)
			shiftval
			OPT_SINCE="$OPT_VAL"
			if ! batextras:git rev-parse "$OPT_SINCE" &> /dev/null; then
				printc "%{RED}%s: unknown commit or tag for '%s'\n" "$PROGRAM" "$OPT"
				exit 1
			fi
			;;

		--badidea)
			OPT_BAD_IDEA=true
			;;

		*)
			printc "%{RED}%s: unknown option '%s'%{CLEAR}" "$PROGRAM" "$OPT"
			exit 1
			;;
	esac
done

# -----------------------------------------------------------------------------
# Verify the version matches today's date.

VERSION="$(source "${LIB}/constants.sh" && echo "${PROGRAM_VERSION}")"
VERSION_EXPECTED="$(date +%Y.%m.%d)"

if [[ "$VERSION" != "$VERSION_EXPECTED" ]] && ! "$OPT_BAD_IDEA"; then
	printc "%{RED}The expected version does not match %{DEFAULT}version.txt%{RED}!%{CLEAR}\n"
	printc "%{RED}Expected: %{YELLOW}%s%{CLEAR}\n" "$VERSION_EXPECTED"
	printc "%{RED}Actual:   %{YELLOW}%s%{CLEAR}\n" "$VERSION"
	exit 1
fi

# -----------------------------------------------------------------------------
# Verify the working tree is clean-ish.

if ! "$OPT_BAD_IDEA"; then
	while read -r flags file; do
		if [[ "$flags" =~ M ]]; then
			printc "%{RED}Found an uncommitted change in %{DEFAULT}%s%{RED}!%{CLEAR}\n" "$file"
			exit 1
		fi
	done < <(batextras:git status --porcelain)
fi

# -----------------------------------------------------------------------------
# Build files.

# Clean the old files.
# Make sure it's not trying to delete /bin or /man first, though.
if [[ "$OPT_BIN_DIR" != "/bin" ]]; then rm -rf "$OPT_BIN_DIR"; fi
if [[ "$OPT_MAN_DIR" != "/man" ]]; then rm -rf "$OPT_MAN_DIR"; fi

# Generate the new bin files.
printc "%{YELLOW}Building scripts...%{CLEAR}\n"
"$HERE/build.sh" --minify=all --alternate-executable='bat' --no-inline &>/dev/null || {
	printc "%{RED}FAILED TO BUILD SCRIPTS.%{CLEAR}\n"
	printc "%{RED}CAN NOT PROCEED WITH RELEASE.%{CLEAR}\n"
	exit 1
}

# -----------------------------------------------------------------------------
# Build package.

printc "%{YELLOW}Packaging artifacts...%{CLEAR}\n"
batextras:create_package "$OPT_ARTIFACT"
printc "%{YELLOW}Package created as %{BLUE}%s%{YELLOW}.%{CLEAR}\n" "$OPT_ARTIFACT"

# -----------------------------------------------------------------------------
# Print template description package.

printc "%{YELLOW}Release description:%{CLEAR}\n"
batextras:generate_release_notes \
	"$(batextras:get_previous_tag_name)" \
	"$(batextras:get_current_commit)"
