# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2020 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------

# Gets the width of the terminal.
# This will return 80 unless stdin is attached to the terminal.
#
# Returns:
#     The terminal width, or 80 if there's no TTY.
#
term_width() {
	if ! [[ -t 0 ]]; then
		echo "80"
		return 0
	fi

	# shellcheck disable=SC2155
	local width="$(stty size 2>/dev/null | cut -d' ' -f2)"
	if [[ -z "$width" ]]; then
		echo "80"
	else
		echo  "$width"
	fi
}
