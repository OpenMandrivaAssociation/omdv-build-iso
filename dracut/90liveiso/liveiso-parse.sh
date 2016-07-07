#!/bin/sh
# live images are specified with
# root=live:backingdev

[ -z "$root" ] && root=$(getarg root=)

if [ "${root%%:*}" = "live" ] ; then
    liveroot=$root
fi

[ "${liveroot%%:*}" = "live" ] || return 1

modprobe -q iso9660
modprobe -q loop
modprobe -q squashfs
modprobe -q overlay

case "$liveroot" in
    live:LABEL=*|LABEL=*) \
        root="${root#live:}"
        root="$(echo $root | sed 's,/,\\x2f,g')"
        root="live:/dev/disk/by-label/${root#LABEL=}"
        rootok=1 ;;
    live:UUID=*|UUID=*) \
        root="${root#live:}"
        root="live:/dev/disk/by-uuid/${root#UUID=}"
        rootok=1 ;;
esac

[ "$rootok" = "1" ] || return 1

info "root was $liveroot, is now $root"

# make sure that init doesn't complain
[ -z "$root" ] && root="live"

wait_for_dev /run/initramfs/union

return 0
