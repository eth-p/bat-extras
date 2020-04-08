batwatch() {
	"${BIN_DIR}/batwatch${BIN_SUFFIX}" "$@" || return $?
}
