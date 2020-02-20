setup() {
	use_shim 'batgrep'
}

test:regular_file() {
	description "Search for a pattern in a regular file."
	snapshot stdout
	snapshot stderr

	batgrep "ca" file.txt
}

test:symlink_file() {
	description "Search for a pattern in a symlinked file."
	snapshot stdout
	snapshot stderr

	batgrep "ca" link.txt
}

test:output_with_color() {
	description "Snapshot test for colored output."
	snapshot stdout
	snapshot stderr

	batgrep "ca" file.txt --color=always
}

test:output_without_color() {
	description "Snapshot test for colored output."
	snapshot stdout
	snapshot stderr

	batgrep "ca" file.txt --color=never
}

test:search_regex() {
	description "Search for a regex pattern."
	snapshot stdout
	snapshot stderr

	batgrep "^[cb]" file.txt
}

test:search_fixed() {
	description "Search for fixed strings."
	snapshot stdout
	snapshot stderr

	batgrep --fixed-strings '$' file.txt
}

test:option_context() {
	description "Search and use the context option."
	snapshot stdout
	snapshot stderr

	batgrep -C 0 '\$' file.txt
}
