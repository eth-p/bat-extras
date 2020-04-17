setup() {
	source "${LIB}/dsl.sh"
}

# Expect functions.
expect_dsl_command() {
	EXPECTED_DSL_ARGS=("$@")
	CALLED="not called"

	dsl_on_command() {
		expect_equal "$# args" "${#EXPECTED_DSL_ARGS[@]} args"
		CALLED="called"
		local arg
		local i=0
		for arg in "$@"; do
			expect_equal "$arg" "${EXPECTED_DSL_ARGS[$i]}"
			((i++)) || true
		done
	}

	dsl_parse
	expect_equal "$CALLED" "called"
}

expect_dsl_option() {
	EXPECTED_DSL_ARGS=("$@")
	CALLED="not called"

	dsl_on_option() {
		expect_equal "$# args" "${#EXPECTED_DSL_ARGS[@]} args"
		CALLED="called"
		local arg
		local i=0
		for arg in "$@"; do
			expect_equal "$arg" "${EXPECTED_DSL_ARGS[$i]}"
			((i++)) || true
		done
	}

	dsl_parse
	expect_equal "$CALLED" "called"
}

# Stub methods.
dsl_on_command() {
	:
}

dsl_on_command_commit() {
	:
}

dsl_on_option() {
	:
}

# Test cases.
test:parse_command() {
	description "Parses a DSL command."

	expect_dsl_command "my-command" <<-EOF
		my-command
	EOF
}

test:parse_simple_args() {
	description "Parses a DSL command with simple args"

	expect_dsl_command "my-command" "arg1" "arg2" "arg3" <<-EOF
		my-command arg1 arg2 arg3
	EOF
}

test:parse_quoted_args() {
	description "Parses a DSL command with quoted args"

	expect_dsl_command "my-command" "arg 1" "" "arg3" <<-EOF
		my-command "arg 1" "" "arg3
	EOF
}

test:parse_escaped_args() {
	description "Parses a DSL command with escaped args"

	# Note: Bash will escape the \\ into \. It's only doubled in this heredoc.
	expect_dsl_command "my-command" "arg\"1" "arg 2" "arg\\3" <<-EOF
		my-command arg\"1 arg\ 2 arg\\\\3
	EOF
}

test:parse_option() {
	description "Parses a DSL option with simple arguments"

	expect_dsl_option "my-option" "1" "2" "3" <<-EOF
		my-command
		    my-option 1 2 3
	EOF
}
