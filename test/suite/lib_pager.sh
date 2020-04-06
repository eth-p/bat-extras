setup() {
	source "${LIB}/pager.sh"
}

use_pager() {
	unset BAT_PAGER
	export PAGER="$1"

	SCRIPT_PAGER_CMD=("$PAGER")
	SCRIPT_PAGER_ARGS=()

	_detect_pager --force
	_configure_pager
}

use_bat_pager() {
	unset PAGER
	export BAT_PAGER="$1"

	SCRIPT_PAGER_CMD=($BAT_PAGER)
	SCRIPT_PAGER_ARGS=()

	_detect_pager --force
	_configure_pager
}

test:less_detection() {
	description "Identify less"

	use_pager "less"             && expect_equal "$(pager_name)" "less"
	use_pager "less_but_renamed" && expect_equal "$(pager_name)" "less"
	use_pager "tput"             && expect_equal "$(pager_name)" "tput"
}

test:less_version() {
	description "Identify less version"

	export MOCK_LESS_VERSION=473
	use_pager "less" && expect_equal "$(pager_version)" "473"

	export MOCK_LESS_VERSION=551
	use_pager "less" && expect_equal "$(pager_version)" "551"
}

test:less_args() {
	description "Automatically select appropriate less args"

	export MOCK_LESS_VERSION=473
	use_pager "less"
	expect array_contains "-R" in "${SCRIPT_PAGER_ARGS[@]}"
	expect array_contains "--quit-if-one-screen" in "${SCRIPT_PAGER_ARGS[@]}"
	expect array_contains "--no-init" in "${SCRIPT_PAGER_ARGS[@]}"

	export MOCK_LESS_VERSION=551
	use_pager "less"
	expect array_contains "-R" in "${SCRIPT_PAGER_ARGS[@]}"
	expect array_contains "--quit-if-one-screen" in "${SCRIPT_PAGER_ARGS[@]}"
	expect ! array_contains "--no-init" in "${SCRIPT_PAGER_ARGS[@]}"

	use_pager "not_less"
	expect_equal "${#SCRIPT_PAGER_ARGS[@]}" 0
}

test:env_bat_pager() {
	description "Check that BAT_PAGER is being used"

	use_bat_pager "not_less"
	expect_equal "$SCRIPT_PAGER_CMD" "not_less"

	use_bat_pager "not_less but not_more"
	expect_equal "$SCRIPT_PAGER_CMD" "not_less"
	expect_equal "${SCRIPT_PAGER_CMD[1]}" "but"
	expect_equal "${SCRIPT_PAGER_CMD[2]}" "not_more"
}
