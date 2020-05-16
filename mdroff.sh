#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2020 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------

printf_msg() {
	printf "$@" 1>&2
}

printf_err() {
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
}

mdroff:emit:link() {
	printf "%s" "$1"
}

mdroff:emit:table_heading() {
	printf '.P\n\\fB'
	printf '%s ' "$@"
	printf '\\fR\n'
	
	# Emit separator.
	printf '.br\n'
	local cell
	for cell in "$@"; do
		printf "%$(wc -c <<< "$cell")s" '' | tr ' ' '-'
		printf " "
	done
	printf "\n"
}

mdroff:emit:table_row() {
	printf '.br\n'
	printf '%s ' "$@"
	printf '\n'
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

mdroff:parseln() {
	MDROFF_ATTR_STRONG=false
	MDROFF_ATTR_EMPHASIS=false
	
	local buffer="$1"
	local before
	local found
	local pos
	
	while [[ "${#buffer}" -gt 0 ]]; do
		[[ "$buffer" =~ \*{1,3}|\[([^\]]+)\]\(([^\)]+)\) ]] || {
			printf "%s\n" "$buffer"
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
	MDROFF_IN_TABLE=false
	MDROFF_PARAGRAPH=false
	
	local line
	local empty=0
	local empty_continue=0
	while IFS='' read -r line; do
		line="$(mdroff:parseln "$line")"
		
		# Empty
		if [[ "$line" =~ ^[[:space:]]*$ ]]; then
			((empty_continue++)) || true
			MDROFF_PARAGRAPH=true
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
			local cells=()
			line="$(sed 's/^[[:space:]]*|//; s/|[[:space:]]*$//' <<< "$line")"
			
			# shellcheck disable=SC2206
			IFS='|' cells=($line)
			
			if [[ "${cells[0]}" =~ ^[[:space:]]*-+[[:space:]]*$ ]]; then
				continue
			fi
			
			if ! "$MDROFF_IN_TABLE"; then
				MDROFF_IN_TABLE=true
				mdroff:emit table_heading "${cells[@]}"
			else
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
