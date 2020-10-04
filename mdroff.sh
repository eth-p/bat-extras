#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2020 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------
# shellcheck disable=SC2021
# shellcheck disable=SC2155

printf_msg() {
	# shellcheck disable=SC2059
	printf "$@" 1>&2
}

printf_err() {
	# shellcheck disable=SC2059
	printf "$@" 1>&2
}

# -----------------------------------------------------------------------------
# MDroff:
# -----------------------------------------------------------------------------

mdroff:emit:h1() {
	printf '.TH "%s" 1\n' "$1"
}

mdroff:emit:h2() {
	printf '.SH "%s"\n' "$1"
}

mdroff:emit:h3() {
	echo "$1"
}

mdroff:emit:h4() {
	echo "$1"
}

mdroff:emit:h5() {
	echo "$1"
}

mdroff:emit:line() {
	if "$MDROFF_PARAGRAPH"; then
		MDROFF_PARAGRAPH=false
		printf ".P\n%s\n" "$1"
	else
		printf ".br\n%s\n" "$1"
	fi
}

mdroff:emit:attr() {
	printf '\\fR'
	
	if "$MDROFF_ATTR_STRONG"; then
		printf '\\fB'
	fi
	
	if "$MDROFF_ATTR_EMPHASIS"; then
		printf '\\fI'
	fi
	
	if "$MDROFF_ATTR_CODE"; then
		printf '\\fI'
	fi
}

mdroff:emit:link() {
	printf "%s" "$1"
}


# shellcheck disable=SC2034
mdroff:emit:table_start() {
	printf ".TS\n"
	printf "tab(|) box;\n"
	
	# Print Header Alignment
	local temp
	for temp in "$@"; do printf "| cB "; done
	printf "|\n"
	
	# Print Separator
	for temp in "$@"; do printf "| _ "; done
	printf "|\n"
	
	# Print Column Alignment
	local cols=("$@")
	printf "| "
	printf "%s0 |1 " "${cols:0:$((${#@}-1))}"
	printf "%s " "${cols[$((${#@}-1))]}"
	printf "|.\n"
}

mdroff:emit:table_end() {
	printf ".TE\n\n"
}

mdroff:emit:table_heading() {
	local heading="$(printf "| %s " "$@")"
	printf "%s\n" "${heading:1}"
	
	# Prevent tbl warning.
	for temp in "${@:2}"; do printf "|"; done
	printf "\n"
	
	# Start table data.
	printf ".SP\n"
}

mdroff:emit:table_row() {
	local row="$(printf "| %s " "$@")"
	printf "%s\n" "${row:1}"
}

mdroff:emit() {
	local type="$1"
	local data="$2"
	
	if type "mdroff:rewrite:${type}" &>/dev/null; then
		data="$("mdroff:rewrite:${type}" "${@:2}")"
	fi
	
	if type "mdroff:emit_hook:${type}" &>/dev/null; then
		"mdroff:emit_hook:${type}" "$data" "${@:3}"
		return
	fi
	
	"mdroff:emit:${type}" "$data" "${@:3}"
}

mdroff:trim() {
	sed 's/^[[:space:]]*//; s/[[:space:]]*$//' <<< "$1"
}

mdroff:parseln() {
	MDROFF_ATTR_STRONG=false
	MDROFF_ATTR_EMPHASIS=false
	MDROFF_ATTR_CODE=false
	
	local buffer="$1"
	local before
	local found
	local pos
	
	while [[ "${#buffer}" -gt 0 ]]; do
		[[ "$buffer" =~ \*{1,3}|\`|\[([^\]]+)\]\(([^\)]+)\) ]] || {
			printf "%s\n" "$(mdroff:trim "$buffer")"
			return
		}
		
		found="${BASH_REMATCH[0]}"
		pos="$(awk -v search="$found" '{print index($0,search) - 1}' <<< "$buffer")"
		
		before="${buffer:0:$pos}"
		buffer="${buffer:$(($pos + ${#found}))}"
		
		printf "%s" "$before"
		case "$found" in
			'***')
				if "$MDROFF_ATTR_STRONG" && "$MDROFF_ATTR_EMPHASIS"; then
					MDROFF_ATTR_STRONG=false
					MDROFF_ATTR_EMPHASIS=false
				else
					MDROFF_ATTR_STRONG=true
					MDROFF_ATTR_EMPHASIS=true
				fi 
				mdroff:emit attr
				;;

			'**')	
				if "$MDROFF_ATTR_STRONG"; then
					MDROFF_ATTR_STRONG=false
				else
					MDROFF_ATTR_STRONG=true
				fi
				mdroff:emit attr
				;;

			'*')
				if "$MDROFF_ATTR_EMPHASIS"; then
					MDROFF_ATTR_EMPHASIS=false
				else
					MDROFF_ATTR_EMPHASIS=true
				fi
				mdroff:emit attr
				;;

			'`')
				if "$MDROFF_ATTR_CODE"; then
					MDROFF_ATTR_CODE=false
				else
					MDROFF_ATTR_CODE=true
				fi
				mdroff:emit attr
				;;
				

			'['*)
				mdroff:emit link "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
		esac
	done
}

mdroff() {
	MDROFF_HEADING_LEVEL=0
	MDROFF_HEADING=''
	MDROFF_ATTR_STRONG=false
	MDROFF_ATTR_EMPHASIS=false
	MDROFF_ATTR_CODE=false
	MDROFF_IN_TABLE=false
	MDROFF_PARAGRAPH=false
	MDROFF_TABLE_HEADER=()
	
	local line
	local empty=0
	local empty_continue=0
	while IFS='' read -r line; do
		line="$(mdroff:parseln "$line")"
		
		# Empty
		if [[ "$line" =~ ^[[:space:]]*$ ]]; then
			((empty_continue++)) || true
			if "$MDROFF_IN_TABLE"; then
				mdroff:emit table_end	
			fi
			
			MDROFF_PARAGRAPH=true
			MDROFF_TABLE_HEADER=()
			MDROFF_IN_TABLE=false
			continue
		fi
		
		empty="$empty_continue"
		empty_continue=0
		
		# Headings
		if [[ "$line" =~ ^(#{1,})[[:space:]]{1,}(.*)$ ]]; then
			local level="${#BASH_REMATCH[1]}"
			local text="${BASH_REMATCH[2]}"
			
			MDROFF_HEADING_LEVEL="$level"
			MDROFF_HEADING="$text"
			
			mdroff:emit "h${level}" "$text"
			MDROFF_PARAGRAPH=true
			continue
		fi
		
		# Tables (Partially Supported)
		if [[ "$line" =~ ^[[:space:]]*\| ]]; then
			local raw_cells=()
			local cells=()
			local table_cell
			
			line="$(sed 's/^[[:space:]]*|//; s/|[[:space:]]*$//' <<< "$line")"
			
			# shellcheck disable=SC2206
			IFS='|' raw_cells=($line)
			for table_cell in "${raw_cells[@]}"; do
				cells+=("$(mdroff:trim "$table_cell")")
			done
			
			if [[ "${cells[0]}" =~ ^[[:space:]]*-+[[:space:]]*$ ]]; then
				# Calculate the column alignments.
				local table_alignments=()
				local table_cell
				
				for table_cell in "${cells[@]}"; do
					case "$table_cell" in
						:-*:)
							table_alignments+=('c')
							;;
						:-*)
							table_alignments+=('l')
							;;
						*-:)
							table_alignments+=('r')
							;;
						*)
							table_alignments+=('l') # Unknown, but let's assume left.
					esac
				done
				
				# Emit the table start and table header.
				mdroff:emit table_start "${table_alignments[@]}"
				mdroff:emit table_heading "${MDROFF_TABLE_HEADER[@]}"
				MDROFF_TABLE_HEADER=()
				continue
			fi
			
			if ! "$MDROFF_IN_TABLE"; then
				MDROFF_IN_TABLE=true
				MDROFF_TABLE_HEADER=("${cells[@]}")
			else
				if [[ "${#MDROFF_TABLE_HEADER[@]}" -ne 0 ]]; then
					mdroff:emit table_heading "${MDROFF_TABLE_HEADER[@]}"
					MDROFF_TABLE_HEADER=()	
				fi
				
				mdroff:emit table_row "${cells[@]}"
			fi
		
			MDROFF_PARAGRAPH=true
			continue	
		fi
		
		mdroff:emit line "$line"
	done < <(sed 's/<br *\/?>//')
}

# -----------------------------------------------------------------------------
# bat-extras:
# -----------------------------------------------------------------------------

mdroff:rewrite:h1() {
	emitted_name=false
	emitted_description=false
	sed 's/^bat-extras: //' <<< "$1" | tr '[[:lower:]]' '[[:upper:]]'
}


mdroff:emit_hook:h2() {
	case "$MDROFF_HEADING" in
		"Installation") return ;;
		"Issues?")      return ;;
	esac
	
	mdroff:emit:h2 "$(tr '[[:lower:]]' '[[:upper:]]' <<< "$1")"
}

mdroff:emit_hook:line() {
	if [[ "$MDROFF_HEADING_LEVEL" = "1" ]] && [[ "$emitted_name" != true ]]; then
		emitted_name=true
		printf ".SH NAME\n%s - %s\n" "$(sed 's/^bat-extras: //' <<< "$MDROFF_HEADING" | tr '[[:upper:]]' '[[:lower:]]')" "$1"
		printf ".SH DESCRIPTION\n"
		return
	fi
	
	case "$MDROFF_HEADING" in
		"Installation") return ;;
		"Issues?")      return ;;
	esac
	
	mdroff:emit:line "$@"
}

# -----------------------------------------------------------------------------
# Main:
# -----------------------------------------------------------------------------

if [[ "${#BASH_SOURCE[@]}" -eq 1 ]]; then
	case "$1" in
		"") mdroff ;;
		*) {
			if ! [ -f "$1" ]; then
				printf_err "%s: cannot find or read file %s\n" "$0" "$1" 
				exit 1;	
			fi
			
			mdroff < "$1"
		} ;;
	esac
fi
