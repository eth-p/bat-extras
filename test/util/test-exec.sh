#!/usr/bin/env bash
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNNER="${HERE}/test-runner.sh"
TEST_DATA="${HERE}/../data"

# Test data.
TEST_ID="$2"
TEST_SCRIPT="${HERE}/../tests/${TEST_ID}.sh"
TEST_OUT="$(mktemp)"
TEST_OUT2="$(mktemp)"
TEST_OUT_SNAPSHOT="${HERE}/../tests/${TEST_ID}.snapshot"

# Functions.
pass() {
	printf "\x1B[33mTest [%s]:\x1B[32m %s\x1B[0m\n" "$TEST_ID" "Passed"
	exit 0
}	

fail() {
	printf "\x1B[33mTest [%s]:\x1B[31m %s\x1B[0m\n" "$TEST_ID" "Failed"
	case "$1" in
		EXIT)
			local c="in packaged script"
			if [ "$2" = "bin" ]; then
				c="in source script"
			fi

			if [[ "$TEST_QUIET" != "true" ]]; then	
				printf "\x1B[33mError (%s):\x1B[0m\n" "$c"
				bat --style=numbers --paging=never -
			fi
			;;

		DIFF)
			printf "\x1B[33m%s\x1B[0m\n" "$2"
			if [[ "$TEST_QUIET" != "true" ]]; then	
				printf "\x1B[33mDifference:\x1B[0m\n"
				bat --style=plain --paging=never -l diff -
			fi
			;;
	esac
	exit 1
}

run() {
	({
		cd "$TEST_DATA"
		export TEST_RUNNER="$RUNNER"
		export TEST_RUNNER_USE="$1"
		bash "$TEST_SCRIPT" >"$2" 2>&1 || exit $?
	}) || fail EXIT "$1" < "$2"
}

# Run the test command.
case "$1" in
	snapshot-generate) {
		run src "$TEST_OUT"
		mv "$TEST_OUT" "$TEST_OUT_SNAPSHOT"
		printf "\x1B[33mTest [%s]:\x1B[35m %s\x1B[0m\n" "$1" "Updated"
	};;
		
	snapshot-test) {
		run src "$TEST_OUT"
		SNAPSHOT_DIFF="$(diff "$TEST_OUT" "$TEST_OUT_SNAPSHOT")"
		if [ -z "$SNAPSHOT_DIFF" ]; then
			pass
		else
			fail DIFF "The current revision does not match the snapshot." <<< "$SNAPSHOT_DIFF"
		fi
	};;

	consistency-test) {
		run src "$TEST_OUT"
		run bin "$TEST_OUT2"
		SNAPSHOT_DIFF="$(diff "$TEST_OUT" "$TEST_OUT2")"
		if [ -z "$SNAPSHOT_DIFF" ]; then
			pass
		else
			fail DIFF "The current built and executed scripts act differently." <<< "$SNAPSHOT_DIFF"
		fi
	};;

	*) {
		printf "\x1B[31mUnknown subcommand.\x1B[0m\n"
		printf " - \x1B[33msnapshot-generate\x1B[0m  -- generate new snapshots\n"
		printf " - \x1B[33msnapshot-test\x1B[0m      -- compare current revision with snapshots\n"
		printf " - \x1B[33mconsistency-test\x1B[0m   -- compare current revision packaged and loose scripts\n"
	};;
esac

