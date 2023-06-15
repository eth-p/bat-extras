#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2019-2023 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------

REPO_URL="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}"

# Get the current commit.
CURRENT_COMMIT="${GITHUB_SHA:-$(git -C "$GITHUB_WORKSPACE" rev-parse HEAD)}"
CURRENT_COMMIT_BLOB_URL="${REPO_URL}/blob/${CURRENT_COMMIT}"
CURRENT_COMMIT_URL="${REPO_URL}/commit/${CURRENT_COMMIT}"

CURRENT_COMMIT_DATE_YEAR="$(git -C "${GITHUB_WORKSPACE}" show -s --format="%cd" --date="format:%Y" "${CURRENT_COMMIT}")"
CURRENT_COMMIT_DATE_MONTH="$(git -C "${GITHUB_WORKSPACE}" show -s --format="%cd" --date="format:%m" "${CURRENT_COMMIT}")"
CURRENT_COMMIT_DATE_MONTH_HUMAN="$(git -C "${GITHUB_WORKSPACE}" show -s --format="%cd" --date="format:%B" "${CURRENT_COMMIT}")"
CURRENT_COMMIT_DATE_DAY="$(git -C "${GITHUB_WORKSPACE}" show -s --format="%cd" --date="format:%d" "${CURRENT_COMMIT}")"

# Get the latest released version.
LATEST_TAG_COMMIT="$(git -C "${GITHUB_WORKSPACE}" rev-list --tags --max-count=1)"
LATEST_TAG_NAME="$(git -C "${GITHUB_WORKSPACE}" describe --tags --abbrev=0 "${LATEST_TAG_COMMIT}")"

# Get the current version.
CURRENT_VERSION="${LATEST_TAG_NAME}-snapshot ($(git -C "${GITHUB_WORKSPACE}" rev-parse --short "${CURRENT_COMMIT}"))}"

# Change the version string and commit URL if a tag.
if [[ "${GITHUB_REF_TYPE:-branch}" = "tag" ]]; then
    CURRENT_COMMIT_BLOB_URL="${REPO_URL}/blob/${GITHUB_REF_NAME}"
    if git -C "${GITHUB_WORKSPACE}" describe --tags --exact &>/dev/null; then
        CURRENT_VERSION="$(git -C "${GITHUB_WORKSPACE}" describe --tags --abbrev=0)"
    fi
fi
