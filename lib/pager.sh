#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2019 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------

# Returns 0 (true) if the current pager is less, otherwise 1 (false).
is_pager_less() {
	[[ "$(pager_name)" = "less" ]]
	return $?
}

# Returns 0 (true) if the current pager is bat, otherwise 1 (false).
is_pager_bat() {
	[[ "$(pager_name)" = "bat" ]]
	return $?
}

# Returns 0 (true) if the current pager is disabled, otherwise 1 (false).
is_pager_disabled() {
	[[ -z "$(pager_name)" ]]
	return $?
}

# Prints the detected pager name.
pager_name() {
	_detect_pager 1>&2
	echo "$_SCRIPT_PAGER_NAME"
}

# Prints the detected pager version.
pager_version() {
	_detect_pager 1>&2
	echo "$_SCRIPT_PAGER_VERSION"
}

# Executes a command or function, and pipes its output to the pager (if it exists).
#
# Returns: The exit code of the command.
# Example:
#     pager_exec echo hi
pager_exec() {
	if [[ -n "$SCRIPT_PAGER_CMD" ]]; then
		"$@" | pager_display
		return $?
	else
		"$@"
		return $?
	fi
}

# Displays the output of a command or function inside the pager (if it exists).
#
# Example:
#     bat | pager_display
pager_display() {
	if [[ -n "$SCRIPT_PAGER_CMD" ]]; then
		if [[ -n "$SCRIPT_PAGER_ARGS" ]]; then
			"${SCRIPT_PAGER_CMD[@]}" "${SCRIPT_PAGER_ARGS[@]}"
			return $?
		else
			"${SCRIPT_PAGER_CMD[@]}"
			return $?
		fi
	else
		cat
		return $?
	fi
}

# -----------------------------------------------------------------------------

# Detect the pager information.
# shellcheck disable=SC2120
_detect_pager() {
	if [[ "$_SCRIPT_PAGER_DETECTED" = "true" ]]; then return; fi
	_SCRIPT_PAGER_DETECTED=true

	# If the pager command is empty, the pager is disabled.
	if [[ -z "${SCRIPT_PAGER_CMD[0]}" ]]; then
		_SCRIPT_PAGER_VERSION=0
		_SCRIPT_PAGER_NAME=""
		return;
	fi

	# Determine the pager name and version.
	local output
	local output1
	output="$("${SCRIPT_PAGER_CMD[0]}" --version 2>&1)"
	output1="$(head -n 1 <<<"$output")"

	if [[ "$output1" =~ ^less[[:blank:]]([[:digit:]]+) ]]; then
		_SCRIPT_PAGER_VERSION="${BASH_REMATCH[1]}"
		_SCRIPT_PAGER_NAME="less"
	elif [[ "$output1" =~ ^bat(cat)?[[:blank:]]([[:digit:]]+) ]]; then
		# shellcheck disable=SC2034
		__BAT_VERSION="${BASH_REMATCH[2]}"
		_SCRIPT_PAGER_VERSION="${BASH_REMATCH[2]}"
		_SCRIPT_PAGER_NAME="bat"
	else
		_SCRIPT_PAGER_VERSION=0
		_SCRIPT_PAGER_NAME="$(basename "${SCRIPT_PAGER_CMD[0]}")"
	fi
}

# Configure the script pager.
# This attempts to mimic how bat determines the pager and pager arguments.
#
# 1. Use BAT_PAGER
# 2. Use PAGER with special arguments for less
# 3. Use PAGER
_configure_pager() {
	# shellcheck disable=SC2206
	SCRIPT_PAGER_ARGS=()
	if [[ -n "${PAGER+x}" ]]; then
		SCRIPT_PAGER_CMD=($PAGER)
	else
		SCRIPT_PAGER_CMD=("less")
	fi

	# Prefer the BAT_PAGER environment variable.
	if [[ -n "${BAT_PAGER+x}" ]]; then
		# [note]: This is intentional.
		# shellcheck disable=SC2206
		SCRIPT_PAGER_CMD=($BAT_PAGER)
		SCRIPT_PAGER_ARGS=()
		return
	fi
	
	# If the pager is bat, use less instead.
	if is_pager_bat; then
		SCRIPT_PAGER_CMD=("less")
		SCRIPT_PAGER_ARGS=()
	fi

	# Add arguments for the less pager.
	if is_pager_less; then
		SCRIPT_PAGER_CMD=("${SCRIPT_PAGER_CMD[0]}" -R --quit-if-one-screen)
		if [[ "$(pager_version)" -lt 500 ]]; then
			SCRIPT_PAGER_CMD+=(--no-init)
		fi
	fi
}

# -----------------------------------------------------------------------------

if [[ -t 1 ]]; then
	# Detect and choose the arguments for the pager.
	_configure_pager
else
	# Prefer no pager if not a tty.
	SCRIPT_PAGER_CMD=()
	SCRIPT_PAGER_ARGS=()
fi
