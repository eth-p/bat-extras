setup() {
	source "${LIB}/version.sh"
}

test:compare_eq() {
	description "Compare version: -eq"

	expect version_compare "1.2.3" -eq "1.2.3"
	expect version_compare "1.2.0" -eq "1.2"
	expect version_compare "1.2" -eq "1.2.0"
	expect ! version_compare "1.2.3" -eq "1.2.0"
	expect ! version_compare "1.2.3" -eq "1.2"
}

test:compare_ne() {
	description "Compare version: -ne"

	expect version_compare "1.2.3" -ne "1.2.4"
	expect version_compare "1.2.1" -ne "1.2"
	expect version_compare "1.2" -ne "1.2.1"
	expect ! version_compare "1.2.0" -ne "1.2.0"
	expect ! version_compare "1.2.0" -ne "1.2"
}

test:compare_lt() {
	description "Compare version: -lt"

	expect version_compare "1.2.3" -lt "1.2.4"
	expect version_compare "1.2" -lt "1.2.4"
	expect version_compare "1.2.12" -lt "1.3.0"
	expect ! version_compare "1.4.0" -lt "1.3.12"
	expect ! version_compare "1.4.0" -lt "1.4.0"
}

test:compare_gt() {
	description "Compare version: -gt"

	expect version_compare "1.2.4" -gt "1.2.3"
	expect version_compare "1.2.4" -gt "1.2"
	expect version_compare "1.3.0" -gt "1.2.12"
	expect ! version_compare "1.3.12" -gt "1.4.0"
	expect ! version_compare "1.4.0" -gt "1.4.0"
}

test:compare_le() {
	description "Compare version: -le"

	expect version_compare "1.2.3" -le "1.2.4"
	expect version_compare "1.2" -le "1.2.4"
	expect version_compare "1.2.12" -le "1.3.0"
	expect ! version_compare "1.4.0" -le "1.3.12"
	expect version_compare "1.4.0" -le "1.4.0"
}

test:compare_ge() {
	description "Compare version: -gt"

	expect version_compare "1.2.4" -ge "1.2.3"
	expect version_compare "1.2.4" -ge "1.2"
	expect version_compare "1.3.0" -ge "1.2.12"
	expect ! version_compare "1.3.12" -ge "1.4.0"
	expect version_compare "1.4.0" -ge "1.4.0"
}
