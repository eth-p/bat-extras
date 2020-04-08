HAS_RIPGREP=false

setup() {
	use_shim 'batgrep'

	if command -v rg &>/dev/null; then
		HAS_RIPGREP=true
	fi
}

require_rg() {
	if ! "$HAS_RIPGREP"; then
		skip "Ripgrep (rg) is not installed."
	fi
}

test:version() {
	description "Test 'batgrep --version'"
	snapshot stdout
	snapshot stderr

	batgrep --version | head -n1 | cut -d' ' -f1
	batgrep --version | awk 'p{print} /^$/ { p=1 }'
}

test:regular_file() {
	description "Search for a pattern in a regular file."
	snapshot stdout
	snapshot stderr

	require_rg

	batgrep "ca" file.txt
}

test:symlink_file() {
	description "Search for a pattern in a symlinked file."
	snapshot stdout
	snapshot stderr

	require_rg

	batgrep "ca" link.txt
}

test:output_with_color() {
	description "Snapshot test for colored output."
	snapshot stdout
	snapshot stderr

	require_rg

	batgrep "ca" file.txt --color=always
}

test:output_without_color() {
	description "Snapshot test for colored output."
	snapshot stdout
	snapshot stderr

	require_rg

	batgrep "ca" file.txt --color=never
}

test:search_regex() {
	description "Search for a regex pattern."
	snapshot stdout
	snapshot stderr

	require_rg

	batgrep "^[cb]" file.txt
}

test:search_fixed() {
	description "Search for fixed strings."
	snapshot stdout
	snapshot stderr

	require_rg

	batgrep --fixed-strings '$' file.txt
}

test:option_context() {
	description "Search and use the context option."
	snapshot stdout
	snapshot stderr

	require_rg

	batgrep -C 0 '\$' file.txt
}
