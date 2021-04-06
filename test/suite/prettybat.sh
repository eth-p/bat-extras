setup() {
	use_shim 'prettybat'
}

test:version() {
	description "Test 'prettybat --version'"
	snapshot stdout
	snapshot stderr

	prettybat --version | awk 'FNR <= 1 { print $1 }'
	prettybat --version | awk 'p{print} /^$/ { p=1 }'
}

test:read_from_pipe() {
	description "Test 'prettybat -'"

	assert_equal "ABC" "$(echo "ABC" | prettybat)" 
	assert_equal "ABC" "$(echo "ABC" | prettybat -)" 
}

test:read_from_pipe_with_formatter() {
	description "Test 'prettybat - -lsh'"

	assert_equal "-: shfmt" "$(echo "" | prettybat - -lsh --debug:formatter)" 
}
