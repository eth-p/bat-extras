# This test suite is meant to check the performance impact of loading the library scripts used in bat-extras.
# Whether or not it completes successfully doesn't matter.

# Test cases.
test:perf_baseline() {
	description "The baseline for test execution time"
	exit 0
}

test:perf_lib_constants() {
	description "Record how long it takes to load the constants.sh library"
	source "${LIB}/constants.sh"
	exit 0
}

test:perf_lib_dsl() {
	description "Record how long it takes to load the dsl.sh library"
	source "${LIB}/dsl.sh"
	exit 0
}

test:perf_lib_opt() {
	description "Record how long it takes to load the opt.sh library"
	source "${LIB}/opt.sh"
	exit 0
}

test:perf_lib_opt_hook_color() {
	description "Record how long it takes to load the opt_hook_color.sh library"
	source "${LIB}/opt_hook_color.sh"
	exit 0
}

test:perf_lib_opt_hook_pager() {
	description "Record how long it takes to load the opt_hook_pager.sh library"
	source "${LIB}/opt_hook_pager.sh"
	exit 0
}

test:perf_lib_opt_hook_version() {
	description "Record how long it takes to load the opt_hook_version.sh library"
	source "${LIB}/opt_hook_version.sh"
	exit 0
}

test:perf_lib_opt_hook_width() {
	description "Record how long it takes to load the opt_hook_width.sh library"
	source "${LIB}/opt_hook_width.sh"
	exit 0
}

test:perf_lib_pager() {
	description "Record how long it takes to load the pager.sh library"
	source "${LIB}/pager.sh"
	exit 0
}

test:perf_lib_print() {
	description "Record how long it takes to load the print.sh library"
	source "${LIB}/print.sh"
	exit 0
}

test:perf_lib_str() {
	description "Record how long it takes to load the str.sh library"
	source "${LIB}/str.sh"
	exit 0
}

test:perf_lib_version() {
	description "Record how long it takes to load the version.sh library"
	source "${LIB}/version.sh"
	exit 0
}
