set -e
"$TEST_RUNNER" batgrep "ca" file.txt
"$TEST_RUNNER" batgrep "ca" link.txt

