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

test:watcher() {
	description "Test 'batwatch <file>'"
  fail "No longer fails silently due to incorrect flag to stat."

  # Refactored to get here, but when it passes it will loop forever.

  assert batwatch $0
}
