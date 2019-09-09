#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2019 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="${HERE}/../lib"
source "${LIB}/print.sh"
# -----------------------------------------------------------------------------

# Runs a test.
#
# Arguments:
#     1  -- The test name.
#     2  -- The test action.
#
# Returns:
#     0  -- The test passed.
#     1  -- The test failed.
run_test() {
	local test_name="$1"
	local test_action="$2"

	bash "$HERE/util/test-exec.sh" "$test_action" "$test_name"
	return $?
}

# Runs all tests.
#
# Arguments:
#     1  -- The test action.
#
# Variables:
#     RESULT      -- "pass" or "fail".
#     RESULT_PASS -- The number of tests that passed.
#     RESULT_FAIL -- The number of tests that failed.
run_all_tests() {
	local test_action="$1"

	RESULT="pass"
	RESULT_PASS=0
	RESULT_FAIL=0

	for test in "$HERE"/tests/*.sh; do
		if run_test "$(basename "$test" .sh)" "$test_action"; then
			((RESULT_PASS++))
		else
			((RESULT_FAIL++))
			RESULT="fail"
		fi
	done

	if [ "$RESULT" = "fail" ]; then
		return 1
	else
		return 0
	fi
}

# Displays a summary of the tests run.
display_test_summary() {
	local tpc
	local tfc

	[[ "$RESULT_PASS" -gt 0 ]] && tpc="GREEN" || tpc="CLEAR";
	[[ "$RESULT_FAIL" -gt 0 ]] && tfc="RED"   || tfc="CLEAR";

	printc "%{YELLOW}RESULT: %{${tpc}}%s%{YELLOW} passed, %{${tfc}}%s%{YELLOW} failed.%{CLEAR}\n" \
		"$RESULT_PASS" \
		"$RESULT_FAIL"
}

# -----------------------------------------------------------------------------

if [ -n "$1" ]; then
	run_all_tests "$1"
	exit_status=$?
	display_test_summary
	exit $exit_status
fi

# Run all actions.
FINAL_RESULT="pass"
for action in "snapshot-test" "consistency-test"; do
	printc "%{CYAN}Running %{CLEAR}%s%{CYAN} tests:%{CLEAR}\n" "$action"
	run_all_tests "$action"
	display_test_summary
	printf "\n"

	if [[ "$RESULT" = "fail" ]]; then
		FINAL_RESULT=fail
	fi
done

case "$FINAL_RESULT" in
	pass) exit 0;;
	fail) exit 1;;
esac

