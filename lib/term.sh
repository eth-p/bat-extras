# ----------------------------------------------------------------------------------------------------------------------
# bat-extras | Copyright (C) 2020 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# ----------------------------------------------------------------------------------------------------------------------

# Gets the width of the terminal.
# This will return 80 unless stdin is attached to the terminal.
#
# Returns:
#     The terminal width, or 80 if there's no TTY.
#
term_width() {
	# shellcheck disable=SC2155
	local width="$({ stty size 2>/dev/null || echo "22 80"; } | cut -d ' ' -f2)"
	if [[ "$width" -ne 0 ]]; then
		echo "$width"
	else
		echo "80"
	fi
	return 0
}

# Clears the terminal using the ANSI escape sequences for erase screen and cursor absolute positioning.
term_clear() {
	printf "\x1B[3J\x1B[2J\x1B[H"
}
