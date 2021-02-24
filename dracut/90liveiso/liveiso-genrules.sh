#!/bin/sh

case "$root" in
  live:/dev/*)
    {
        printf 'KERNEL=="%s", RUN+="/sbin/initqueue --settled --onetime --unique /sbin/liveiso-root $env{DEVNAME}"\n' \
            ${root#live:/dev/}
        printf 'SYMLINK=="%s", RUN+="/sbin/initqueue --settled --onetime --unique /sbin/liveiso-root $env{DEVNAME}"\n' \
            ${root#live:/dev/}
    } >> /etc/udev/rules.d/99-liveiso.rules
    wait_for_dev "${root#live:}"
  ;;
  live:*)
  modprobe loop
    if [ -f "${root#live:}" ]; then
        /sbin/initqueue --settled --onetime --unique /sbin/liveiso-root "${root#live:}"
    fi
  ;;
esac
