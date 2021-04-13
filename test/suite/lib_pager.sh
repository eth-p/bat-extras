setup() {
	source "${LIB}/pager.sh"
}

use_pager() {
	unset BAT_PAGER
	export PAGER="$1"

	_configure_pager
	_detect_pager
}

use_no_pager() {
	unset BAT_PAGER
	unset PAGER

	_configure_pager
	_detect_pager
}

use_bat_pager() {
	unset PAGER
	export BAT_PAGER="$1"

	_configure_pager
	_detect_pager
}

test:less_detection() {
	description "Identify less"

	(use_pager "less"             && expect_equal "$(pager_name)" "less")
	(use_pager "less_but_renamed" && expect_equal "$(pager_name)" "less")
	(use_pager "stty"             && expect_equal "$(pager_name)" "stty")
}

test:bat_detection() {
	description "Ensure bat is replaced with less as pager"

	use_pager "bat"
	expect_equal "$(pager_name)" "less"
	expect array_contains "-R" in "${SCRIPT_PAGER_CMD[@]}"
}

test:less_version() {
	description "Identify less version"

	(
		export MOCK_LESS_VERSION=473
		use_pager "less" && expect_equal "$(pager_version)" "473"
	)

	(
		export MOCK_LESS_VERSION=551
		use_pager "less" && expect_equal "$(pager_version)" "551"
	)
}

test:less_args() {
	description "Automatically select appropriate less args"

	# When pager is "less".
	(
		export MOCK_LESS_VERSION=473
		use_pager "less"
		expect array_contains "-R" in "${SCRIPT_PAGER_CMD[@]}"
		expect array_contains "--quit-if-one-screen" in "${SCRIPT_PAGER_CMD[@]}"
		expect array_contains "--no-init" in "${SCRIPT_PAGER_CMD[@]}"
	)

	# When pager is equivalent of "less".
	(
		export MOCK_LESS_VERSION=551
		use_pager "less"
		expect array_contains "-R" in "${SCRIPT_PAGER_CMD[@]}"
		expect array_contains "--quit-if-one-screen" in "${SCRIPT_PAGER_CMD[@]}"
		expect ! array_contains "--no-init" in "${SCRIPT_PAGER_CMD[@]}"
	)
}

test:less_args_not_less() {
	description "Don't give non-less pagers the less args"

	use_pager "not_less"
	echo "${SCRIPT_PAGER_CMD[@]}"
	expect_equal "${#SCRIPT_PAGER_CMD[@]}" 1
}

test:env_bat_pager() {
	description "Check that BAT_PAGER is being used"

	use_bat_pager "not_less"
	expect_equal "${SCRIPT_PAGER_CMD[0]}" "not_less"

	use_bat_pager "not_less but not_more"
	expect_equal "${SCRIPT_PAGER_CMD[0]}" "not_less"
	expect_equal "${SCRIPT_PAGER_CMD[1]}" "but"
	expect_equal "${SCRIPT_PAGER_CMD[2]}" "not_more"
}

test:env_no_pager() {
	description "Check that no PAGER or BAT_PAGER defaults to less"
	
	use_no_pager
	expect_equal "${SCRIPT_PAGER_CMD[0]}" "less"
	expect array_contains "-R" in "${SCRIPT_PAGER_CMD[@]}"
}

test:args_copied_from_pager() {
	description "Check that the pager args are correct with PAGER."

	use_pager "less --some-argument"
	expect_equal "${SCRIPT_PAGER_CMD[0]}" "less"
	expect_not_equal "${SCRIPT_PAGER_CMD[1]}" "--some-argument"
}

test:args_copied_from_bat_pager() {
	description "Check that the pager args are correct with PAGER."

	use_bat_pager "less --some-argument"
	assert_equal "${#SCRIPT_PAGER_CMD[@]}" 2
	expect_equal "${SCRIPT_PAGER_CMD[0]}" "less"
	expect_equal "${SCRIPT_PAGER_CMD[1]}" "--some-argument"
}
