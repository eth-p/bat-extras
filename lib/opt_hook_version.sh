#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2019 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------

# Option parser hook: --version support.
# This will accept --version, which prints the version information and exits.
hook_version() {
	SHIFTOPT_HOOKS+=("__shiftopt_hook__version")
	__shiftopt_hook__version() {
		if [[ "$OPT" = "--version" ]]; then
			printf "%s %s\n\n%s\n%s\n" \
				"$PROGRAM" \
				"$PROGRAM_VERSION" \
				"$PROGRAM_COPYRIGHT" \
				"$PROGRAM_HOMEPAGE"
			exit 0
		fi

		return 1
	}
}
