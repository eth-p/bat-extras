batpipe() {
	"$(batpipe_path)" "$@" || return $?
}

batpipe_path() {
	echo "${BIN_DIR}/batpipe${BIN_SUFFIX}"
}
