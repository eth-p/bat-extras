#!/bin/bash

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

test:help() {
	description "Test 'batwatch --help'"
  snapshot stdout
  batwatch --help

  assert batwatch --help
  batwatch --help | grep -q 'Usage'
}

test:displayed() {
	description "Test 'batwatch <file>': <file> should be displayed'"
  snapshot stdout

  batwatch --no-clear --watcher poll file.sh <<< "q"
  batwatch --watcher poll file.sh <<< "q" | grep -q "Hello"
}
