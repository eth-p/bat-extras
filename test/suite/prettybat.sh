setup() {
	use_shim 'prettybat'
}

test:version() {
	description "Test 'prettybat --version'"
	snapshot stdout
	snapshot stderr

	prettybat --version | head -n1 | cut -d' ' -f1
	prettybat --version | awk 'p{print} /^$/ { p=1 }'
}
