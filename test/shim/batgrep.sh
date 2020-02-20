batgrep() {
	"${BIN_DIR}/batgrep${BIN_SUFFIX}" "$@" || return $?
}
