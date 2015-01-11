#!/bin/sh

. /lib/dracut-lib.sh

[ -f /tmp/root.info ] && . /tmp/root.info

PATH=/usr/sbin:/usr/bin:/sbin:/bin

[ -z "$1" ] && exit 1
livedev="$1"

# create live tree
mkdir -m 0755 -p /live/distrib
mkdir -m 0755 -p /live/media
mkdir -m 0755 -p /live/tmpfs
mkdir -m 0755 -p /live/union

# fix udev isohybrid LABEL issues (mga #3334)
# by reading the device we get, stripping away partition number,
# and mount the resulting device
realdev=$(echo $livedev |sed 's,\(/dev/sd[a-z]\)1,\1,g')

# mount the live media
getargbool 0 UEFI && liveuefi="yes"
if [ -n "$liveuefi" ]; then
    mount -n -t vfat -o ro $livedev /live/media
else
    mount -n -t iso9660 -o ro $realdev /live/media
fi

LOOPDEV=$( losetup -f )
losetup -r $LOOPDEV /live/media/LiveOS/squashfs.img
mount -n -t squashfs -o ro $LOOPDEV /live/distrib
mount -n -t tmpfs -o mode=755 /live/tmpfs /live/tmpfs
# mount aufs as new root
echo "aufs live/union aufs defaults 0 0" >> /etc/fstab
mount -n -t aufs -o br=/live/tmpfs:/live/distrib /live/union

ln -s /live/union /dev/root

printf '/bin/mount --rbind /live/union %s\n' "$NEWROOT" > $hookdir/mount/01-$$-live.sh

need_shutdown

exit 0
