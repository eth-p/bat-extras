setup() {
	use_shim 'batpipe'
}

test:detected_bash_shell() {
	description "Test it can detect a bash shell."
	command -v "bash" &>/dev/null || skip "Test requires bash shell."
	
	output="$(SHELL="bash" bash --login -c "{ \"$(batpipe_path)\"; }")" # This hack prevents bash from exec()'ing itself.
	grep '^LESSOPEN=' <<< "$output" >/dev/null || fail "Detected the wrong shell for bash."
}

test:detected_fish_shell() {
	description "Test it can detect a fish shell."

	# Note: We don't use bash's `-c` option when testing with a fake fish shell.
	# Bash `-c` will automatically exec() into the last process, which loses the
	# argv0 we intentionally named after a different shell.

	# Test detection via `*sh -l` parent process.
	output="$(printf "%q" "$(batpipe_path)" | fish -l)"
	grep '^set -x' <<< "$output" >/dev/null || fail 'Detected wrong shell when checking parent process args.'

	# Test detection via hypen-prefixed parent process.
	output="$(printf "%q" "$(batpipe_path)" | SHIM_ARGV0='-fish' fish)"
	grep '^set -x' <<< "$output" >/dev/null || fail 'Detected wrong shell when checking parent process.'
}

test:detected_nu_shell() {
	description "Test it can detect a nushell shell."

	# Note: We don't use bash's `-c` option when testing with a fake nu shell.
	# Bash `-c` will automatically exec() into the last process, which loses the
	# argv0 we intentionally named after a different shell.

	# Test detection via `*sh -l` parent process.
	output="$(printf "%q" "$(batpipe_path)" | nu -l)"
	grep '^\$env' <<< "$output" >/dev/null || fail 'Detected wrong shell when checking parent process args.'

	# Test detection via hypen-prefixed parent process.
	output="$(printf "%q" "$(batpipe_path)" | SHIM_ARGV0='-nu' nu -l)"
	grep '^\$env' <<< "$output" >/dev/null || fail 'Detected wrong shell when checking parent process.'
}

test:detected_less_with_path_argument() {
	description "Test it detects less when less opens a file by an absolute path."

	# Drive less, letting it invoke batpipe as its LESSOPEN preprocessor, with a
	# file opened by an absolute path -- exactly how files are normally opened
	# (`less /home/user/file.txt`). less's command line then ends in that path;
	# batpipe must detect "less" from the executable name only. Taking the
	# basename of the *whole* command line yields the file's basename instead,
	# so batpipe wrongly concludes it is not inside less and disables color.
	export BATPIPE_DEBUG=1
	export LESSOPEN="|$(batpipe_path) %s"

	output="$(less "${PWD}/file.txt" 2>&1)"
	grep 'BATPIPE_INSIDE_LESS: true' <<< "$output" >/dev/null \
		|| fail "Did not detect less as the parent when opening a file by an absolute path."
}

test:viewer_gzip() {
	description "Test it can view .gz files."
	command -v "gunzip" &>/dev/null || skip "Test requires gunzip."
	
	assert_equal "$(batpipe compressed.txt.gz)" "OK"
}

test:batpipe_term_width() {
	description "Test support for BATPIPE_TERM_WIDTH"
	snapshot STDOUT

	export BATPIPE=color
	export BATPIPE_DEBUG_PARENT_EXECUTABLE=less

	BATPIPE_TERM_WIDTH=40 batpipe file.txt
	BATPIPE_TERM_WIDTH=-20 batpipe file.txt
}
