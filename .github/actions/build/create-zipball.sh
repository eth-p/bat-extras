#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2019-2023 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

set -euo pipefail
source "${HERE}/version.sh"
# -----------------------------------------------------------------------------

ZIPFILE="${GITHUB_WORKSPACE}/dist/bat-extras-${CURRENT_VERSION/\.//}.zip"

[[ -d "${GITHUB_WORKSPACE}/dist" ]] || mkdir -p "${GITHUB_WORKSPACE}/dist"
[[ ! -e "${ZIPFILE}" ]] || rm "${ZIPFILE}" 

cd "${GITHUB_WORKSPACE}"
zip -r "$ZIPFILE" "bin"
zip -ru "$ZIPFILE" "doc"
zip -ru "$ZIPFILE" "man)"
