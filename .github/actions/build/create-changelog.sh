#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2019-2023 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="${GITHUB_WORKSPACE}/lib"
SRC="${GITHUB_WORKSPACE}/src"

set -euo pipefail
source "${HERE}/version.sh"
# -----------------------------------------------------------------------------

# Get the release date string.
DATE_SUFFIX=""
case "$(( $CURRENT_COMMIT_DATE_DAY ))" in
	11 | 12 | 13) DATE_SUFFIX="th" ;;
	*1) DATE_SUFFIX="st" ;;
	*2) DATE_SUFFIX="nd" ;;
	*3) DATE_SUFFIX="rd" ;;
	*)  DATE_SUFFIX="th" ;;
esac
DATE_STR="${CURRENT_COMMIT_DATE_MONTH_HUMAN} ${CURRENT_COMMIT_DATE_DAY}${DATE_SUFFIX}, ${CURRENT_COMMIT_DATE_YEAR}"

# Get the script names.
script_links=()
script_names=()
for script in "$SRC"/*.sh; do
	script_name="$(basename "$script" .sh)"
	script_names+=("$script_name")
	script_links+=("[\`${script_name}\`](${CURRENT_COMMIT_BLOB_URL}/doc/${script_name}.md)")
done

script_pattern="$(printf 's/\\(%s\\)/`\\1`/;' "${script_names[@]}")"
SCRIPTS="$(printf "%s, " "${script_links[@]:0:$((${#script_links[@]} - 1))}")"
SCRIPTS="${SCRIPTS}and ${script_links[$((${#script_links[@]} - 1))]}"

# Generate the changelog.
CHANGELOG_DEV=''
CHANGELOG=''

ref="${CURRENT_COMMIT}"
end="${LATEST_TAG_COMMIT}"
echo "ref=${ref}"
echo "end=${end}"
while [[ "$ref" != "$end" ]]; do
	echo "see: $ref"
	is_developer=false
	ref_message="$(git -C "${GITHUB_WORKSPACE}" show -s --format=%s "$ref")"
	ref="$(git -C "${GITHUB_WORKSPACE}" rev-parse "${ref}~1")"

	if [[ "$ref_message" =~ ^([a-z-]+):[[:space:]]*(.*)$ ]]; then
		affected_module="${BASH_REMATCH[1]}"

		# Make module names consistent.
		case "$affected_module" in
			dev | lib | mdroff) affected_module="developer" ;;
			tests) affected_module="test" ;;
			doc) affected_module="docs" ;;
		esac

		# Switch to the correct changelog.
		case "$affected_module" in
			test | developer | ci | build) is_developer=true ;;
		esac
	fi

	# Append to changelog.
	if "$is_developer"; then
		CHANGELOG_DEV="$CHANGELOG_DEV"$'\n'" - ${ref_message}"
	else
		CHANGELOG="$CHANGELOG"$'\n'" - ${ref_message}"
	fi
done

CHANGELOG="$(sed "$script_pattern" <<< "$CHANGELOG")"
CHANGELOG_DEV="$(sed "$script_pattern" <<< "$CHANGELOG_DEV")"

# Print the changelog.
{ sed '/\\$/{N;s/\\\n//;s/\n//p;}' | tee "${GITHUB_WORKSPACE}/generated-changelog.md"; } <<- EOF
	This contains the latest versions of $SCRIPTS as of commit [$CURRENT_COMMIT]($CURRENT_COMMIT_URL) (${DATE_STR}).
	
	### Changes
	$CHANGELOG
	
	### Developer
	<details>
	<div markdown="1">
	
	$CHANGELOG_DEV
	
	</div>
	</details>
EOF
