#! /bin/sh

clearpart_method=
clearpart_need_method=

clearpart_handler () {
	eval set -- "$(getopt -o '' -l linux,all,drives:,initlabel -- "$@")" || { warn_getopt clearpart; return; }
	while :; do
		case $1 in
			--linux)
				warn "clearing all Linux partitions not supported yet"
				shift
				;;
			--all)
				ks_log "can't clear multiple drives; assuming just the first one"
				clearpart_need_method=1
				# TODO: I bet this isn't safe for installs
				# from USB ...
				ks_preseed d-i partman-auto/disk string /dev/discs/disc0/disc
				# The above breaks when udev is configured
				# to avoid devfs-style device names, so we
				# have to write out a partman hook on the
				# fly to handle this properly if the tools
				# are available.
				ks_write_script /lib/partman/display.d/01kickseed <<'EOF'
#! /bin/sh
set -e
# Generated by kickseed for 'clearpart --all'.

. /usr/share/debconf/confmodule

# Only run the first time.
if [ -f /var/lib/partman/initial_auto ]; then
	exit 0
fi

if type list-devices >/dev/null 2>&1; then
	FIRSTDISK="$(list-devices disk | head -n1)"
	logger -t kickseed "Clearing first disk ($FIRSTDISK) for Kickstart 'clearpart --all'"
	db_set partman-auto/disk "$FIRSTDISK"
fi

exit 0
EOF
				shift
				;;
			--drives)
				case $2 in
					*,*)
						warn "clearing multiple drives not supported"
						;;
					*)
						clearpart_need_method=1
						disk="$2"
						case $disk in
							/dev/*)
								;;
							*)
								disk="/dev/$disk"
								;;
						esac
						ks_preseed d-i partman-auto/disk string "$disk"
						;;
				esac
				shift 2
				;;
			--initlabel)
				ks_preseed d-i partman/confirm_write_new_label boolean true
				shift
				;;
			--)	shift; break ;;
			*)	warn_getopt clearpart; return ;;
		esac
	done
}

clearpart_final () {
	if [ "$clearpart_need_method" ]; then
		if [ -z "$clearpart_method" ]; then
			clearpart_method=regular
		fi
		# needed as of partman-auto 55
		ks_preseed d-i partman-auto/method string "$clearpart_method"
	fi
}

register_final clearpart_final
