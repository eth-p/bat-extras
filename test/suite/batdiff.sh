setup() {
	use_shim 'batdiff'
}

test:version() {
	description "Test 'batdiff --version'"
	snapshot stdout
	snapshot stderr

	batdiff --version | awk 'FNR <= 1 { print $1 }'
	batdiff --version | awk 'p{print} /^$/ { p=1 }'
}
