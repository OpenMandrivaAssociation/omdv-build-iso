#!/bin/bash
DIST=omdv
TYPE=kde4
TREE=cooker
ARCH=`uname -m`
SUDO=sudo
[ "`id -u`" = "0" ] && SUDO=""

[ -n "$1" ] && TREE="$1"
[ -n "$2" ] && TYPE="$2"
[ -n "$3" ] && ARCH="$3"
[ -n "$4" ] && DIST="$4"

[ "$ARCH" = "i386" ] && ARCH=i586

parsePkgList() {
	LINE=0
	cat "$1" |while read r; do
		LINE=$((LINE+1))
		SANITIZED="`echo $r |sed -e 's,	, ,g;s,  *, ,g;s,^ ,,;s, $,,;s,#.*,,'`"
		[ -z "$SANITIZED" ] && continue
		if [ "`echo $SANITIZED |cut -b1-9`" = "%include " ]; then
			INC="`echo $SANITIZED |cut -b10-`"
			if ! [ -e "$INC" ]; then
				echo "ERROR: Package list doesn't exist: $INC (included from $1 line $LINE)" >&2
				exit 1
			fi
			parsePkgList "`echo $SANITIZED |cut -b10-`"
			continue
		fi
		echo $SANITIZED
	done
}

ROOT="`mktemp -d /tmp/liverootXXXXXX`"
[ -z "$ROOT" ] && ROOT=/tmp/liveroot.$$
$SUDO mkdir -p "$ROOT"/tmp

[ -d iso-pkg-lists ] || git clone https://abf.io/openmandriva/iso-pkg-lists.git
cd iso-pkg-lists
$SUDO urpmi.addmedia --urpmi-root "$ROOT" --distrib http://abf-downloads.abf.io/$TREE/repository/$ARCH
$SUDO urpmi.update --urpmi-root "$ROOT" -a
parsePkgList ${DIST}-${TYPE}.lst |xargs $SUDO urpmi --urpmi-root "$ROOT" --no-install --download-all "$ROOT"/tmp --auto --prefer /default-kde4-config/
cd ..

