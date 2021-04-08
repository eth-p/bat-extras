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
	description "Test it can detect a bash shell."
	command -v "fish" &>/dev/null || skip "Test requires fish shell."
	fish -c 'exit 0' &>/dev/null || skip "Test requires fish shell." # This is in case it finds "fish" in shimexec dir.
	
	output="$(SHELL="fish" fish --login -c "$(batpipe_path)")"
	grep '^set -x' <<< "$output" >/dev/null || fail "Detected the wrong shell for fish."
}

test:viewer_gzip() {
	description "Test it can view .gz files."
	command -v "gunzip" &>/dev/null || skip "Test requires gunzip."
	
	assert_equal "$(batpipe compressed.txt.gz)" "OK"
}
