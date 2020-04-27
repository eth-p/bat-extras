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
