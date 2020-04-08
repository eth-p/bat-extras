setup() {
	use_shim 'batwatch'
}

test:version() {
	description "Test 'batwatch --version'"
	snapshot stdout
	snapshot stderr

	batwatch --version | head -n1 | cut -d' ' -f1
	batwatch --version | awk 'p{print} /^$/ { p=1 }'
}
