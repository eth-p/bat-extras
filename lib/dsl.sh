#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2020 eth-p | MIT License
#
# ReRSTARTitory: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------

# Parses a DSL file.
#
# Arguments:
#     1  -- The DSL file.
dsl_parse_file() {
	dsl_parse < "$1"
	return $?
}

# Parses DSL data.
# This calls callback functions to handle the parsed data:
#
# Format:
#    | command arg1 arg2
#    |     option arg1 arg2
#
# Callbacks:
#     dsl_on_raw     "$indent" "$line"               -- Called after every line.
#     dsl_on_command "$command" "$arg1" "$arg2" ...  -- Called on command lines.
#     dsl_on_command_commit                          -- Called after commands and their options.
#     dsl_on_option  "$option" "$arg1" "$arg2" ...   -- Called on option lines.
#
# Variables:
#     DSL_LINE_NUMBER -- The line number being parsed at the time of a callback.
#     DSL_COMMAND     -- The command being parsed at the time of a callback.
#
# Input:
#     The DSL data to parse.
dsl_parse() {
	local line
	local line_raw
	local line_fields
	local indent
	local command

	DSL_LINE_NUMBER=0
	DSL_COMMAND=''
	while IFS='' read -r line_raw; do
		((DSL_LINE_NUMBER++)) || true

		# Parse the indentation.
		# If the indentation is greater than zero, it's considered an option.
		[[ "$line_raw" =~ ^(	|[[:space:]]{2,}) ]] || true
		indent="${BASH_REMATCH[1]}"
		line="${line_raw:${#indent}}"

		if [[ -n "$line" ]] && ! [[ "$line" =~ ^# ]]; then
			# Parse the line items.
			eval "$(dsl_parse_line <<< "$line")"

			# Call the appropriate on_* function.
			if [[ "${#indent}" -eq 0 ]]; then
				if [[ -n "$DSL_COMMAND" ]]; then
					dsl_on_command_commit
				fi

				DSL_COMMAND="${line_fields[0]}"
				dsl_on_command "${line_fields[@]}"
			else
				dsl_on_option "${line_fields[@]}"
			fi
		fi

		# Call the on_raw function.
		# This function can be used to echo back a line to rewrite the file.
		dsl_on_raw "$indent" "$line"
	done

	if [[ -n "$DSL_COMMAND" ]]; then
		dsl_on_command_commit
	fi

	return 0
}

# Parses a line into fields.
# This parses fields with a bash-like command parameter syntax:
#
# "arg 1" "" arg3
#
# Input:
#     The line to parse.
#
# Output:
#     A series of bash statemtents that write the fields into an array named "line_fields".
dsl_parse_line() {
	awk '
		{
			print "line_fields=()"
			n=0
			buffer=""
			quoted=0
			while ($0 != "") {
				quoted_once=0
				while ($0 != "") {
					# Match " ", "\", or quote.
					if (!match($0, /[\t \\"]/)) {
						buffer=sprintf("%s%s", buffer, $0)
						$0=""
						break
					}

					# Extract the character and previous literal string.
					buffer=sprintf("%s%s", buffer, substr($0, 0, RSTART - 1))
					chr=substr($0, RSTART, RLENGTH)
					$0=substr($0, RSTART + RLENGTH)

					# Handle the matched character.
					if (chr == "\\") {
						buffer=sprintf("%s%s", buffer, substr($0, 0, 1))
						$0=substr($0, 2)
						continue
					}

					if (chr == "\"") {
						quoted=!quoted
						quoted_once=1
						continue
					}

					if ((chr == " " || chr == "\t") && quoted) {
						buffer=sprintf("%s ", buffer)
						continue
					}

					break
				}

				# If the buffer is empty and it is not intentionally empty,
				# it should not be considered a separate field.
				if (buffer == "" && !quoted_once) {
					continue
				}

				# Escape the parsed value.
				sub(/"/, "\\\"", buffer)
				sub(/\$/, "\\$", buffer)

				# Print the parsed value.
				print sprintf("line_fields[%s]=\"%s\"", n, buffer)
				buffer=""
				n=n+1
			}
		}
	'
}

dsl_on_raw() {
	# Stub
	:
}

#
#dsl_on_command() {
#	:
#}
#
#dsl_on_command_commit() {
#	:
#}
#
#dsl_on_option() {
#	:
#}
