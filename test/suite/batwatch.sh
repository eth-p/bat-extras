setup() {
	use_shim 'batwatch'
}

test:version() {
	description "Test 'batwatch --version'"
	snapshot stdout
	snapshot stderr

	batwatch --version | awk 'FNR <= 1 { print $1 }'
	batwatch --version | awk 'p{print} /^$/ { p=1 }'
}
