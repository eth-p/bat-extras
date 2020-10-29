setup() {
	set - --long-implicit implicit_value \
	      --long-explicit=explicit_value \
	      -i implicit \
	      -x=explicit \
	      -I1 group_implicit \
	      -X2=group_explicit \
	      positional_1 \
	      positional_2 \
	      --after-positional

	source "${LIB}/print.sh"
	source "${LIB}/opt.sh"
}

assert_opt_name() {
	assert [ "$OPT" = "$1" ]
}

assert_opt_value() {
	assert [ "$OPT_VAL" = "$1" ]
}

assert_opt_valueless() {
	assert [ -z "$OPT_VAL" ]
}


test:long() {
	description "Parse long options."

	while shiftopt; do
		if [[ "$OPT" = "--long-implicit" ]]; then
			assert_opt_valueless
			return
		fi
	done

	fail 'Failed to find option.'
}

test:long_implicit() {
	description "Parse long options in '--long value' syntax."

	while shiftopt; do
		if [[ "$OPT" = "--long-implicit" ]]; then
			shiftval
			assert_opt_value 'implicit_value'
			return
		fi
	done

	fail 'Failed to find option.'
}

test:long_explicit() {
	description "Parse long options in '--long=value' syntax."

	while shiftopt; do
		if [[ "$OPT" = "--long-explicit" ]]; then
			assert_opt_value 'explicit_value'
			shiftval
			assert_opt_value 'explicit_value'
			return
		fi
	done

	fail 'Failed to find option.'
}

test:short_default() {
	description "Parse short options in '-k' syntax."

	while shiftopt; do
		if [[ "$OPT" = "-i" ]]; then
			assert_opt_valueless
			return
		fi
	done

	fail 'Failed to find option.'
}

test:short() {
	description "Parse short options in '-k val' syntax."

	while shiftopt; do
		if [[ "$OPT" = "-i" ]]; then
			shiftopt
			assert_opt_valueless
			return
		fi
	done

	fail 'Failed to find option.'
}

test:short_implicit() {
	description "Parse short options in '-k value' syntax."

	while shiftopt; do
		if [[ "$OPT" = "-i" ]]; then
			shiftval
			assert_opt_value 'implicit'
			return
		fi
	done

	fail 'Failed to find option.'
}

test:short_explicit() {
	description "Parse short options in '-k=value' syntax."

	while shiftopt; do
		if [[ "$OPT" = "-x" ]]; then
			assert_opt_value 'explicit'
			shiftval
			assert_opt_value 'explicit'
			return
		fi
	done

	fail 'Failed to find option.'
}

test:short_default_mode() {
	description "Ensure the default mode for '-abc' is VALUE."
	assert_equal "$SHIFTOPT_SHORT_OPTIONS" "VALUE"
}

test:short_split_none() {
	description "Parse short options in '-abc' syntax with SPLIT mode."
	SHIFTOPT_SHORT_OPTIONS="SPLIT"

	local found=0
	while shiftopt; do
		case "$OPT" in
			"-I"|"-1")
				assert_opt_valueless
				((found++)) || true
				;;
		esac
	done

	assert_equal "$found" 2
}
	
test:short_split_implicit() {
	description "Parse short options in '-abc val' syntax with SPLIT mode."
	SHIFTOPT_SHORT_OPTIONS="SPLIT"

	local found=0
	while shiftopt; do
		case "$OPT" in
			"-I"|"-1")
				assert_opt_valueless
				shiftval 
				assert_opt_value "group_implicit" 
				((found++)) || true
				;;
		esac
	done

	assert_equal "$found" 2
}
	
test:short_split_explicit() {
	description "Parse short options in '-abc=val' syntax with SPLIT mode."
	SHIFTOPT_SHORT_OPTIONS="SPLIT"

	local found=0
	while shiftopt; do
		case "$OPT" in
			"-X"|"-2")
				assert_opt_value "group_explicit"
				((found++)) || true
				;;
		esac
	done

	assert_equal "$found" 2
}

test:short_pass_none() {
	description "Parse short options in '-abc' syntax with PASS mode."
	SHIFTOPT_SHORT_OPTIONS="PASS"

	local found=0
	while shiftopt; do
		case "$OPT" in
			"-I"|"-1") fail "Short group -I1 was split." ;;
			"-I1")
				assert_opt_valueless
				((found++)) || true
				;;
		esac
	done

	assert_equal "$found" 1
}
	
test:short_pass_implicit() {
	description "Parse short options in '-abc val' syntax with PASS mode."
	SHIFTOPT_SHORT_OPTIONS="PASS"

	local found=0
	while shiftopt; do
		case "$OPT" in
			"-I"|"-1") fail "Short group -I1 was split." ;;
			"-I1")
				assert_opt_valueless
				shiftval 
				assert_opt_value "group_implicit" 
				((found++)) || true
				;;
		esac
	done

	assert_equal "$found" 1
}
	
test:short_pass_explicit() {
	description "Parse short options in '-abc=val' syntax with PASS mode."
	SHIFTOPT_SHORT_OPTIONS="PASS"

	local found=0
	while shiftopt; do
		case "$OPT" in
			"-X"|"-2") fail "Short group -X2 was split." ;;
			"-X2")
				assert_opt_value "group_explicit"
				((found++)) || true
				;;
		esac
	done

	assert_equal "$found" 1
}

test:short_conv_none() {
	description "Parse short options in '-abc' syntax with CONV mode."
	SHIFTOPT_SHORT_OPTIONS="CONV"

	local found=0
	while shiftopt; do
		case "$OPT" in
			"-I"|"-1") fail "Short group -I1 was split." ;;
			"-I1") fail "Short group -I1 was not converted." ;;
			"--I1")
				assert_opt_valueless
				((found++)) || true
				;;
		esac
	done

	assert_equal "$found" 1
}
	
test:short_conv_implicit() {
	description "Parse short options in '-abc val' syntax with CONV mode."
	SHIFTOPT_SHORT_OPTIONS="CONV"

	local found=0
	while shiftopt; do
		case "$OPT" in
			"-I"|"-1") fail "Short group -I1 was split." ;;
			"-I1") fail "Short group -I1 was not converted." ;;
			"--I1")
				assert_opt_valueless
				shiftval 
				assert_opt_value "group_implicit" 
				((found++)) || true
				;;
		esac
	done

	assert_equal "$found" 1
}
	
test:short_conv_explicit() {
	description "Parse short options in '-abc=val' syntax with CONV mode."
	SHIFTOPT_SHORT_OPTIONS="CONV"

	local found=0
	while shiftopt; do
		case "$OPT" in
			"-X"|"-2") fail "Short group -X2 was split." ;;
			"-X2") fail "Short group -X2 was not converted." ;;
			"--X2")
				assert_opt_value "group_explicit"
				((found++)) || true
				;;
		esac
	done

	assert_equal "$found" 1
}

test:short_value_none() {
	description "Parse short options in '-abc' syntax with VALUE mode."
	SHIFTOPT_SHORT_OPTIONS="VALUE"

	local found=0
	while shiftopt; do
		case "$OPT" in
			"-I1") fail "Short group -I1 was not truncated." ;;
			"-I")
				assert_opt_value "1"
				((found++)) || true
				;;
		esac
	done

	assert_equal "$found" 1
}
	
test:short_value_implicit() {
	description "Parse short options in '-abc val' syntax with VALUE mode."
	SHIFTOPT_SHORT_OPTIONS="VALUE"

	local found=0
	while shiftopt; do
		case "$OPT" in
			"-I1") fail "Short group -I1 was not truncated." ;;
			"-I")
				shiftval 
				assert_opt_value "1" 
				((found++)) || true
				;;
		esac
	done

	assert_equal "$found" 1
}
	
test:short_value_explicit() {
	description "Parse short options in '-abc=val' syntax with VALUE mode."
	SHIFTOPT_SHORT_OPTIONS="VALUE"

	local found=0
	while shiftopt; do
		case "$OPT" in
			"-X2") fail "Short group -X2 was not truncated." ;;
			"-X")
				assert_opt_value "2=group_explicit"
				((found++)) || true
				;;
		esac
	done

	assert_equal "$found" 1
}

test:hook() {
	description "Option hooks."
	
	SHIFTOPT_HOOKS=("example_hook")
	
	found=false
	example_hook() {
		if [[ "$OPT" = "--long-implicit" ]]; then
			found=true
			return 0
		fi
		return 1
	}

	while shiftopt; do
		if [[ "$OPT" = "--long-implicit" ]]; then
			fail "Option was not filtered by hook."
		fi
	done
	
	if ! "$found"; then
		fail "Option was not found by hook."
	fi
}

test:fn_setargs() {
	description "Function setargs."

	setargs "--setarg=true"
	shiftopt || true
	shiftval
	
	assert_opt_name "--setarg"
	assert_opt_value "true"
}

test:fn_resetargs() {
	description "Function resetargs."

	setargs "--setarg=true"
	resetargs
	shiftopt || true
	
	assert_opt_name "--long-implicit"
}
