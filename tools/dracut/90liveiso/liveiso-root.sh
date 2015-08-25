#!/bin/sh

. /lib/dracut-lib.sh

[ -f /tmp/root.info ] && . /tmp/root.info

PATH=/usr/sbin:/usr/bin:/sbin:/bin

[ -z "$1" ] && exit 1
livedev="$1"

# create live tree
mkdir -m 0755 -p /run/initramfs/omdv
mkdir -m 0755 -p /run/initramfs/image
mkdir -m 0755 -p /run/initramfs/tmpfs
mkdir -m 0755 -p /run/initramfs/union

# fix udev isohybrid LABEL issues (mga #3334)
# by reading the device we get, stripping away partition number,
# and mount the resulting device
realdev=$(echo $livedev |sed 's,\(/dev/sd[a-z]\)[1-9],\1,g')

# mount the live media
getargbool 0 UEFI && liveuefi="yes"
if [ -n "$liveuefi" ]; then
    mount -n -t vfat -o ro $livedev /run/initramfs/omdv
else
    mount -n -t iso9660 -o ro $realdev /run/initramfs/omdv
fi

LOOPDEV=$( losetup -f )
losetup -r $LOOPDEV /run/initramfs/omdv/LiveOS/squashfs.img
mount -n -t squashfs -o ro $LOOPDEV /run/initramfs/image
mount -n -t tmpfs -o mode=755 /run/initramfs/tmpfs /run/initramfs/tmpfs
# mount aufs as new root
echo "aufs /run/initramfs/union aufs defaults 0 0" >> /etc/fstab
mount -n -t aufs -o br=/run/initramfs/tmpfs:/run/initramfs/image /run/initramfs/union

ln -s /run/initramfs/union /dev/root

if [ -z "$DRACUT_SYSTEMD" ]; then
    printf '/bin/mount --rbind /run/initramfs/union %s\n' "$NEWROOT" > $hookdir/mount/01-$$-live.sh
fi

need_shutdown

exit 0
