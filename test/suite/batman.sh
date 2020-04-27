setup() {
	use_shim 'batman'
}

test:version() {
	description "Test 'batman --version'"
	snapshot stdout
	snapshot stderr

	batman --version | awk 'FNR <= 1 { print $1 }'
	batman --version | awk 'p{print} /^$/ { p=1 }'
}
