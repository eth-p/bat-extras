#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2021 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------

# Gets the path to the parent executable file.
# Arguments:
#     1   -- The target pid. If not provided, the script's parent is used.
parent_executable() {
	local target_pid="${1:-$PPID}"
	ps -f -p "$target_pid" | tail -n 1 | awk '{for(i=8;i<=NF;i++) printf $i" "; printf "\n"}'
}

# Gets the PID of the parent executable file.
# Arguments:
#     1   -- The target pid. If not provided, the script's parent is used.
parent_executable_pid() {
	local target_pid="${1:-$PPID}"
	ps -f -p "$target_pid" | tail -n 1 | awk '{print $3}'
}

# Gets the path to the parent login shell.
# Arguments:
#     1   -- The target pid. If not provided, the script's parent is used.
parent_shell() {
	local target_pid="${1:-$PPID}"
	local target_name
	while true; do
		{
			read -r target_pid
			read -r target_name
			
			# If the parent process starts with a "-", it's a login shell.
			if [[ "${target_name:0:1}" = "-" ]]; then
				target_name="$(cut -f1 -d' ' <<< "${target_name:1}")"
				break
			fi
			
			# If the parent process has "*sh " followed by "-l", it's probably a login shell.
			if [[ "$target_name" =~ sh\ .*-l ]]; then
				target_name="$(cut -f1 -d' ' <<< "${target_name}")"
				break
			fi
			
			# If the parent process is pid 0 (init), then we haven't found a parent shell.
			# At this point, it's best to assume the shell is whatever is defined in $SHELL.
			if [[ "$target_pid" -eq 0 ]]; then
				target_name="$SHELL"
				break
			fi
		} < <({
			ps -f -p "$target_pid" \
				| tail -n 1 \
				| awk '{print $3; for(i=8;i<=NF;i++) printf $i" "; printf "\n"}'
		})
	done
	
	# Ensure that the detected shell is an executable path.
	if [[ -f "$target_name" ]]; then
		echo "$target_name"
	elif ! command -v "$target_name" 2>/dev/null; then
		echo "$target_name" # It's not, but we have nothing else we can do here.
	fi
}
