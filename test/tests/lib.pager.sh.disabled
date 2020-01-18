pager_info() {
	source "${DIR_LIB}/pager.sh"
	printf "\n"
	printf "PAGER=%q\n" "$PAGER"
	printf "BAT_PAGER=%q\n" "$BAT_PAGER"

	printf "SCRIPT_PAGER_CMD=("
	if [[ "${#SCRIPT_PAGER_CMD[@]}" -gt 0 ]]; then
		printf "%q" "${SCRIPT_PAGER_CMD[0]}"
		if [[ "${#SCRIPT_PAGER_CMD[@]}" -gt 1 ]]; then
			printf " %q" "${SCRIPT_PAGER_CMD[@]:1}"
		fi
	fi
	printf ")\n"

	printf "SCRIPT_PAGER_ARGS=("
	if [[ "${#SCRIPT_PAGER_ARGS[@]}" -gt 0 ]]; then
		printf "%q" "${SCRIPT_PAGER_ARGS[0]}"
		if [[ "${#SCRIPT_PAGER_ARGS[@]}" -gt 1 ]]; then
			printf " %q" "${SCRIPT_PAGER_ARGS[@]:1}"
		fi
	fi
	printf ")\n"
}

pager_test() {
	if [[ "$1" = "TTY" ]]; then
		if [[ "$(uname -s)" = "Darwin" ]]; then
			script -q /dev/null bash "${BASH_SOURCE[0]}" --execute
		else
			script -q -c "bash $(printf "%q" "${BASH_SOURCE[0]}") --execute" /dev/null
		fi
	elif [[ "$1" = "FILE" ]]; then
		bash "${BASH_SOURCE[0]}" --execute | cat
	fi
}

if [[ "$1" = "--execute" ]]; then
	pager_info
	exit
fi

# First test.
unset PAGER
unset BAT_PAGER
pager_test TTY

# Second test.
unset PAGER
export BAT_PAGER='less'
pager_test TTY

# Third test.
unset PAGER
export BAT_PAGER='less -R -F'
pager_test TTY

# Forth test.
export PAGER='less'
unset BAT_PAGER
pager_test TTY

# Fifth test.
export PAGER='less -R -F'
unset BAT_PAGER
pager_test TTY

# Sixth test.
export PAGER='less -R -F'
export BAT_PAGER='more'
pager_test TTY

# Final test.
export PAGER='less -R -F'
export BAT_PAGER='more'
pager_test FILE

