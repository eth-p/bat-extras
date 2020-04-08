setup() {
	use_shim 'batman'
}

test:version() {
	description "Test 'batman --version'"
	snapshot stdout
	snapshot stderr

	batman --version | head -n1 | cut -d' ' -f1
	batman --version | awk 'p{print} /^$/ { p=1 }'
}
