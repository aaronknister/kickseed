#! /bin/sh

langsupport_default=

langsupport_handler () {
	eval set -- "$(getopt -o '' -l default: -- "$@")" || die_getopt langsupport
	while :; do
		case $1 in
			--default)
				langsupport_default="$2"
				shift 2
				;;
			--)	shift; break ;;
			*)	die_getopt langsupport ;;
		esac
	done

	if [ $# -eq 0 ]; then
		die "langsupport command requires at least one language"
	fi

	languages="$*"
	if [ "$langsupport_default" ]; then
		languages="$langsupport_default $languages"
	fi

	# requires localechooser 0.04.0ubuntu4
	ks_preseed d-i localechooser/supported-locales multiselect "$languages"
}

langsupport_handler_final () {
	# TODO: no support for different installation and installed languages
	if [ "$lang_value" ] && [ "$langsupport_default" ] && \
			[ "$lang_value" != "$langsupport_default" ]; then
		die "langsupport --default must equal lang"
	fi
}

register_final langsupport_handler_final
