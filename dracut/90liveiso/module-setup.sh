#!/bin/bash

check() {
    # a live host-only image doesn't really make a lot of sense
    [[ $hostonly ]] && return 1
    return 255
}

depends() {
    return 0
}

installkernel() {
    instmods squashfs loop aufs iso9660
}

install() {
    inst_multiple umount dmsetup blkid dd losetup grep blockdev
    inst_multiple -o eject

    inst_hook cmdline 30 "$moddir/liveiso-parse.sh"
    inst_hook cmdline 31 "$moddir/parse-iso-scan.sh"
    inst_hook pre-udev 30 "$moddir/liveiso-genrules.sh"
    inst "$moddir/liveiso-root.sh" "/sbin/liveiso-root"
    inst_script "$moddir/iso-scan.sh" "/sbin/iso-scan"
    # should probably just be generally included
    inst_rules 60-cdrom_id.rules
}
