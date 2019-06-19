#!/usr/bin/env bash
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FAIL=false
ACTION="snapshot-test"

if [ -n "$1" ]; then
	ACTION="$1"
fi

for test in "$HERE"/tests/*.sh; do
	test_name="$(basename "$test" .sh)"
	bash "$HERE/util/test.sh" "$ACTION" "$test_name"
	if [ $? -ne 0 ]; then
		FAIL=true
	fi
done

if [ "$FAIL" = true ]; then
	exit 1
fi

