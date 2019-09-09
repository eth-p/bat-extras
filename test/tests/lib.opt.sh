set -e
source "${DIR_LIB}/opt.sh"

setargs pos1 \
	--val1 for_val1 \
	--val2=for_val2 \
	pos2 \
	--flag1 \
	-v4 for_val4 \
	--flag2 \

# Run a standard option parsing loop.
while shiftopt; do
	case "$OPT" in
		--val*) shiftval; printf "LONG_OPTION:  \"%s\" with value \"%s\"\n" "${OPT}" "${OPT_VAL}" ;;
		--*)              printf "LONG_FLAG:    \"%s\"\n" "${OPT}" ;;
		-v*)    shiftval; printf "SHORT_OPTION: \"%s\" with value \"%s\"\n" "${OPT}" "${OPT_VAL}" ;;
		-*)               printf "SHORT_FLAG:   \"%s\"\n" "${OPT}" ;;
		*)                printf "ARGUMENT:     \"%s\"\n" "${OPT}" ;;
	esac
done

