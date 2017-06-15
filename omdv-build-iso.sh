#!/bin/bash
#set -x
# OpenMandriva Association 2012
# Original author: Bernhard Rosenkraenzer <bero@lindev.ch>
# Modified on 2014 by: Tomasz Pawe³ Gajc <tpgxyz@gmail.com>
# Modified on 2015 by: Tomasz Pawe³ Gajc <tpgxyz@gmail.com>
# Modified on 2015 by: Colin Close <itchka@compuserve.com>
# Modified on 2015 by: Crispin Boylan <cris@beebgames.com>
# Modified on 2016 by: Tomasz Pawe³½ Gajc <tpgxyz@gmail.com>
# Modified on 2016 by: Colin Close <itchka@compuserve.com>
# Modified on 2017 by: Colin Close <itchka@compuserve.com>

# This tool is licensed under GPL license
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#

# This tool is specified to build OpenMandriva Lx distribution ISO

usage_help() {

    if [[ -z "$EXTARCH" && -z "$TREE" && -z "$VERSION" && -z "$RELEASE_ID" && -z "$TYPE" && -z "$DISPLAYMANAGER" ]]; then
	printf "%s\n Please run script with arguments. %s\n"
	printf "%s usage $0 [options] %s\n"
        printf "%s general options:"
        printf "%s --arch= Architecture of packages: i586, x86_64"
        printf "%s --tree= Branch of software repository: cooker, 3.0, openmandriva2014.0"
        printf "%s --version= Version for software repository: 2015.0, 2014.1, 2014.0"
        printf "%s --release_id= Release identifer: alpha, beta, rc, final"
        printf "%s --type= User environment type on ISO: Plasma, KDE4, MATE, LXQt, IceWM, hawaii, xfce4, weston, minimal"
        printf "%s --displaymanager= Display Manager used in desktop environemt: KDM, GDM, LightDM, sddm, xdm, none"
        printf "%s --workdir= Set directory where ISO will be build"
        printf "%s --outputdir= Set destination directory to where put final ISO file"
        printf "%s --debug Enable debug output"
        printf "%s --noclean Do not clean build chroot and keep cached rpms"
        printf "%s --rebuild Clean build chroot and rebuild from cached rpm"
        printf "%s --boot-kernel-type Type of kernel to use for syslinux (eg nrj-desktop), if different from standard kernel"
        printf "%s --debug Enables some developer aids see the README"
        printf "%s --quicken Set up mksqaushfs to use no compression for faster iso builds. Intended mainly for testing"
        printf "%s --keep Use this if you want to be sure to preserve the diffs of your session."
        printf "%s --testrepo Includes the main testing repo in the iso build"
        printf "%s"
        printf "%sFor example:"
        printf "%somdv-build-iso.sh --arch=x86_64 --tree=cooker --version=2015.0 --release_id=alpha --type=lxqt --displaymanager=sddm"
        printf "%sFor detailed usage instructions consult the files in /usr/share/omdv-build-iso/docs/"
        printf "%sExiting."
	exit 1
    else
	return 0
    fi
}

# use only allowed arguments
if [ $# -ge 1 ]; then
    for k in "$@"; do
	case "$k" in
		--arch=*)
        	    EXTARCH=${k#*=}
        	    shift
        	    ;;
#FIXME?
		--tree=*)
		    TREE=${k#*=}
			case "$TREE" in
			    cooker)
				TREE=cooker
            		    ;;
            		    lx3)
            			TREE=3.0
            		    ;;
            		    openmandriva2014.0)
            			TREE=openmandriva2014.0
            		    ;;
            		    *)
            		    TREE="$TREE"
            		    ;;
        		esac
			shift
        		;;
		--version=*)
        	    VERSION=${k#*=}
        	    if [[ "${VERSION,,}" == "cooker" ]]
        	    then
        		VERSION="`date +%Y.0`"
        	    fi
        	    shift
        	    ;;
    		--release_id=*)
        	    RELEASE_ID=${k#*=}
        	    shift
        	    ;;
                --boot-kernel-type=*)
                   BOOT_KERNEL_TYPE=${k#*=}
                  shift
                  ;;
		--type=*)
		    declare -l lc
		    lc=${k#*=}
			case "$lc" in
			    plasma)
				TYPE=PLASMA
				;;
			    kde4)
				TYPE=KDE4
				;;
			    mate)
				TYPE=MATE
				;;
			    lxqt)
				TYPE=LXQt
				;;
			    icewm)
				TYPE=IceWM
				;;
			    hawaii)
				TYPE=hawaii
				;;
			    xfce4)
				TYPE=xfce4
				;;
			    weston)
				TYPE=weston
				;;
			    minimal)
				TYPE=minimal
				;;
			    *)
				printf "%s$TYPE is not supported."
				usage_help
				;;
			esac
        	    shift
        	    ;;
    		--displaymanager=*)
        	    DISPLAYMANAGER=${k#*=}
        	    shift
        	    ;;
        	--workdir=*)
        	    WORKDIR=${k#*=}
        	    shift
        	    ;;
        	--outputdir=*)
        	    OUTPUTDIR=${k#*=}
        	    shift
        	    ;;
    		--debug)
        	    DEBUG=debug
        	    shift
        	    ;;
        	--noclean)
        	    NOCLEAN=noclean
        	    shift
        	    ;;
            --rebuild)
                   REBUILD=rebuild
                   shift
                   ;;
             --quicken)
                   QUICKEN=squashfs
                   shift
                   ;;
             --keep)
                   KEEP=keep
                   shift
                   ;;
             --testrepo)
            	    TESTREPO=testrepo
            	    shift
                   ;;
             --devmode)
                    DEVMODE=devmode
                    shift
                    ;;
             --enable-skip-list)
                    ENSKPLST=enskplst
                    shift
                    ;;
             --help)
        	    usage_help
        	    shift
        	    ;;
    		*)
		    usage_help
        	    ;;
	    esac
	shift
    done
else
    usage_help
fi

# We lose our cli variables when we invoke sudo so we save them
# and pass them to sudo when it is started. Also the user name is needed.
#WHO="$SUDO_USER"
WHO=`id -un`
SUDOVAR=""UHOME="/home/$WHO "EXTARCH="$EXTARCH "TREE="$TREE "VERSION="$VERSION "RELEASE_ID="$RELEASE_ID "TYPE="$TYPE "DISPLAYMANAGER="$DISPLAYMANAGER "DEBUG="$DEBUG \
"NOCLEAN="$NOCLEAN "REBUILD="$REBUILD "WHO="$WHO "WORKDIR="$WORKDIR "OUTPUTDIR="$OUTPUTDIR "ABF="$ABF "QUICKEN="$QUICKEN "KEEP="$KEEP "TESTREPO="$TESTREPO "DEVMODE="$DEVMODE "ENSKPLST="$ENSKPLST"

# WHO=`logname` # If the user is not root at the start then likely we are in ABF ISO builder. 
# run only when root
# Try another way.
#WHO=`id -nu`

if [ "`id -u`" != "0" ]; then
    # We need to be root for umount and friends to work...
    # NOTE the following command will only work on OMDV for the first registered user
    # this user is a member of the wheel group and has root privelidges
    exec sudo -E `echo $SUDOVAR` $0 "$@"
    printf "%s $SUDOVAR %s\n"
    printf "%s -> Run me as root."
    exit 1
fi
WHO=""
echo "$WHO"
#echo "$SUDO_USER"
export $SUDOVAR $SUDO_USER
#echo "These are the sudo variables $SUDOVAR"
# Check whether script is executed inside ABF (https://abf.openmandriva.org)
if [ "$ABF" == "1" ]; then
    IN_ABF=1
    printf "%s\n ->We are in ABF (https://abf.openmandriva.org) environment"
    if [ -n "$NOCLEAN" ]; then
	printf "%s -> You cannot use --noclean inside ABF (https://abf.openmandriva.org)"
	exit 1
    fi
# Allow the use of --workdir if in debug mode
    if  [ -n "$WORKDIR" ] && [ -n  "$DEBUG" ]; then
    printf "%s\n -> using --workdir inside ABF DEBUG instance"
    elif  [ -n  "$WORKDIR" ]; then
	printf "%s\n -> You cannot use --workdir inside ABF (https://abf.openmandriva.org)"
	exit 1
    fi
    
    if [ -n "$KEEP" ]; then
	printf "%s\n -> You cannot use --keep inside ABF (https://abf.openmandriva.org)"
	exit 1
    fi
    if [ -n "$NOCLEAN" ] && [ -n "$REBUILD" ]; then
    printf "%s\n -> You cannot use --noclean and --rebuild together"
    exit 1
    fi
    if [ -n "$REBUILD" ]; then
    printf "%s\n -> You cannot use --rebuild inside ABF (https://abf.openmandriva.org)"
    exit 1
    fi
else
    IN_ABF=0
fi

# default definitions
DIST=omdv
[ -z "$EXTARCH" ] && EXTARCH=`uname -m`
[ -z "${TREE}" ] && TREE=cooker
[ -z "${VERSION}" ] && VERSION="`date +%Y.0`"
[ -z "${RELEASE_ID}" ] && RELEASE_ID=alpha
[ -z "${BUILD_ID}" ] && BUILD_ID=$(($RANDOM%9999+1000))

# always build free ISO
FREE=1
LOGDIR="."

echo "In abf = $IN_ABF"

# Set the $WORKDIR
# If ABF=1 then $WORKDIR codes to /bin on a local system so if you try and test with ABF=1 /bin is rm -rf ed.
# To avoid this and to allow testing use the --debug flag to indicate that the default ABF $WORKDIR path should not be used
# To ensure that the WORKDIR does not get set to /usr/bin if the script is started we check the WORKDIR path used by abfm and
# for further security we check that the script is being run by a non-root user. 
# To allow testing the default ABF WORKDIR is set to a different path if the DEBUG option is set and the user is non-root.
TESTWORKDIR=$(realpath $(dirname $0))
echo $TESTWORKDIR
if [ "$IN_ABF" == "1" ] && [ "$TESTWORKDIR" != "/home/omv/iso_builder" ] && [ -z $DEBUG ]; then
printf "%s\n DO NOT RUN THIS SCRIPT WITH ABF=1 ON A LOCAL SYSTEM WITHOUT SETTING THE DEBUG OPTION"
exit 1
elif [  "$IN_ABF" == "1" ]  && [ -n "$DEBUG" ] && [ "$WHO" != "omv"  ]; then
printf "%s\n Debugging ABF build locally"
#Here we are with ABF=1 and in DEBUG mode,  running on a local system.
# Avoid setting the usual ABF WORKDIR
# if WORKDIR is not defined then set a default'
    if [ -z "$WORKDIR" ]; then
    WORKDIR="$UHOME/omdv-build-chroot-$EXTARCH"
    printf '%s\n' "The build directory is $WORKDIR"
    fi
fi

if [ "$IN_ABF" == "1" ] && [ "$WHO" == "omv" ]; then
    # Hopefully we really are in ABF
    WORKDIR=$(realpath $(dirname $0))
fi

    
if [ "$IN_ABF" == "0" ]; then
    if [ -z "$WORKDIR" ]; then
    WORKDIR="$UHOME/omdv-build-chroot-$EXTARCH"
    fi
fi
printf "%s ->The work directory is $WORKDIR %s\n"
# Define these earlier so that files can be moved easily for the various save options
# this is where rpms are installed
CHROOTNAME="$WORKDIR/BASE"
# this is where ISO files are created
ISOROOTNAME="$WORKDIR/ISO"

# User mode allows three modes of operation.
# All user modes rely on the script being run with no user options to generate  the initial chroot.
# The options are:-
# --noclean Where the chroot (once generated) is reused. 
# --rebuild. Where the chroot/BASE is rebuilt from the initial rpm downloads
# Run without either option and with --workdir pointing to the chroot 
# the script will delete the existing chroot and create a new one.

# For all modes any changes made to the pkg lists are implemented and recorded
# User mode also generates a series of diffs as a record of the multiple sessiona. 
# The --keep option allow these to be retained for subsequent sessions
# The option is disallowed when the build takes place in ABF.
if [ "$IN_ABF" == "0" ] && [ -n "$KEEP" ] && [ -d "$WORKDIR/sessrec" ]; then
$SUDO mv "$WORKDIR/sessrec" "$UHOME"
printf "%s Retaining your session records"
else
printf "%s\n -> No session records exist you must run the script to create them"
fi

if [ "$IN_ABF" == "1" ]  && [ -n "$DEBUG" ] && [ "$WHO" != "omv" ]; then
$SUDO rm -rf "$WORKDIR"
$SUDO mkdir -p "$WORKDIR"
#elif [ "$IN_ABF" == "0" ] && [ -z "$NOCLEAN ]; then
elif [ "$IN_ABF" == "0" ] && [ -n "$REBUILD" ] && [ -d "$WORKDIR" ]; then
printf "%s\n $CHROOTNAME"
$SUDO mv "$CHROOTNAME/var/cache/urpmi/rpms" "$WORKDIR"
$SUDO rm -rf "$WORKDIR/BASE/"
$SUDO rm -rf "$WORKDIR/missing"
$SUDO rm -rf "$WORKDIR/Setting*"
$SUDO rm -rf "$WORKDIR/*.log"
$SUDO rm -rf "$WORKDIR/sessreq"
    if [ -n "$KEEP" ]; then
    $SUDO mv "$UHOME/sessrec" "$WORKDIR"
    fi
#Remake needed directories
$SUDO mkdir -p "$CHROOTNAME/proc" "$CHROOTNAME/sys" "$CHROOTNAME/dev" "$CHROOTNAME/dev/pts"
$SUDO mkdir -p "$CHROOTNAME/var/lib/rpm"
$SUDO mkdir -p "$CHROOTNAME/var/cache/urpmi"
$SUDO mv  "$WORKDIR/rpms" "$CHROOTNAME/var/cache/urpmi/rpms"
    if [ -n "$REBUILD" ] && [ ! -d "$WORKDIR" ]; then
    printf "%s\n -> Error the $WORKDIR does not exist there is nothing to rebuild." 
    printf "%s\n -> Creating a new noclean build which may be used for rebuilding."
    $SUDO mkdir -p "$WORKDIR"
    NOCLEAN=noclean
    fi
elif [ "$IN_ABF" == "0" ] && [ -n "$NOCLEAN" ] && [ -d "$WORKDIR" ]; then #if NOCLEAN option selected then retain the chroot.
	    if [ -d $WORKDIR/sessrec ]; then
        printf "%s\n You have chosen not to clean the base installation %s\n If your build chroot becomes corrupted you may want %s\n to take advantage of the 'rebuild' option to delete the corrupted files %s\n and build a new base installation. %s\n This will be faster than dowloading the rpm packages again" 
        fi
        # Note need to clean out grub uuid files here and maybe others
        if  [ -n "$NOCLEAN" ] && [ ! -d "$WORKDIR" ]; then
        printf "%s\n No base chroot exists...creating one"
        $SUDO mkdir -p "$WORKDIR"
        $SUDO touch "$WORKDIR/.new"
        fi
else
$SUDO rm -rf "$WORKDIR"
$SUDO mkdir -p "$WORKDIR"
fi

# Assign the config build list
FILELISTS="$WORKDIR/iso-pkg-lists-${TREE,,}/${DIST,,}-${TYPE,,}.lst"

# Create the ISO directory
$SUDO mkdir -m 0755 -p "$ISOROOTNAME"/EFI/BOOT
# and the grub diectory
$SUDO mkdir -m 0755 -p "$ISOROOTNAME"/boot/grub

# UUID Generation. xorriso needs a string of 16 asci digits.
# grub2 needs dashes to separate the fields..
GRUB_UUID="`date -u +%Y-%m-%d-%H-%M-%S-00`"
ISO_DATE="`echo "$GRUB_UUID" | sed -e s/-//g`"
# in case when i386 is passed, fall back to i586
[ "$EXTARCH" = "i386" ] && EXTARCH=i586
# ISO name logic
if [ "${RELEASE_ID,,}" == "final" ]; then
    PRODUCT_ID="OpenMandrivaLx.$VERSION-$TYPE"
else
    if [[ "${RELEASE_ID,,}" == "alpha" ]]; then
	RELEASE_ID="$RELEASE_ID.`date +%Y%m%d`"
    fi
    PRODUCT_ID="OpenMandrivaLx.$VERSION-$RELEASE_ID-$TYPE"
fi

LABEL="$PRODUCT_ID.$EXTARCH"
[ `echo $LABEL | wc -m` -gt 32 ] && LABEL="OpenMandrivaLx_$VERSION"
[ `echo $LABEL | wc -m` -gt 32 ] && LABEL="`echo $LABEL |cut -b1-32`"

# urpmi debug
if [ "${DEBUG,,}" == "debug" ]; then
    URPMI_DEBUG=" --debug "
fi



########################
#   Start functions    #
########################

umountAll() {
    printf "%s\n -> Unounting all. %s\n"
    unset KERNEL_ISO
    $SUDO umount -l "$1"/proc 2> /dev/null || :
    $SUDO umount -l "$1"/sys 2> /dev/null || :
    $SUDO umount -l "$1"/dev/pts 2> /dev/null || :
    $SUDO umount -l "$1"/dev 2> /dev/null || :
    $SUDO umount -l "$1"/run/os-prober/dev/* 2> /dev/null || :
    $SUDO umount -l "$IMGNME" 2> /dev/null || :
}

errorCatch() {
    printf "%s\n -> Something went wrong. Exiting %s\n"
    unset KERNEL_ISO
    unset UEFI
    unset MIRRORLIST
    $SUDO losetup -D
if [ -z "$DEBUG" ] || [ -z "$NOCLEAN" ] || [ -z "$REBUILD" ]; then
# for some reason the next line deletes irrespective of flags
#    $SUDO rm -rf $(dirname "$FILELISTS")
    umountAll "$CHROOTNAME"
#    $SUDO rm -rf "$CHROOTNAME"
else
    umountAll "$CHROOTNAME"
fi

#if $1 is set - clean exit
    exit 1
}

# Don't leave potentially dangerous stuff if we had to error out...
trap errorCatch ERR SIGHUP SIGINT SIGTERM

updateSystem() {
printf "%s $WORKDIR"

	$SUDO urpmq --list-url
	$SUDO urpmi.update -a
	
	# Inside ABF, lxc-container which is used to run this script is based
	# on Rosa2012 which does not have cdrtools
	# List of packages that needs to be installed inside lxc-container and local machines
	RPM_LIST="perl-URPM dosfstools grub2 xorriso syslinux squashfs-tools bc imagemagick kpartx omdv-build-iso gdisk gptfdisk parallel"

	printf "%s\n -> Installing rpm files %s\n"
	$SUDO urpmi --downloader wget --wget-options --auth-no-challenge --auto --no-suggests --verify-rpm --ignorearch ${RPM_LIST} --prefer /distro-theme-OpenMandriva-grub2/ --prefer /distro-release-OpenMandriva/ --auto

    # copy contents of /usr/share/omdv-build-iso to the workdir if required
	if [ ! -d $WORKDIR/dracut ]; then
	    printf "%s -> Copying build lists from `rpm -q omdv-build-iso`"
	    find $WORKDIR
	    $SUDO cp -r /usr/share/omdv-build-iso/* "$WORKDIR"
	    touch "$WORKDIR/.new"
	    chown -R "$WHO":"$WHO" "$WORKDIR" #this doesn't do ISO OR BASE
	else
	    printf "%s\n -> Your build lists have been retained" # Files already copied
	fi

    # check file list exists
    if [ ! -e "$FILELISTS" ]; then
#	echo $'\n'
	printf "%s\n -> $FILELISTS does not exist. Exiting"
	errorCatch
    fi
}

getPkgList() {

    # update iso-pkg-lists from ABF if missing
    # we need to do this for ABF to ensure any edits have been included
    # Do we need to do this if people are using the tool locally?

    if [ ! -d $WORKDIR/iso-pkg-lists-${TREE,,} ]; then
#	echo $'\n'
	printf "%s\n -> Could not find $WORKDIR/iso-pkg-lists-${TREE,,}. Downloading from ABF."
	# download iso packages lists from https://abf.openmandriva.org
	PKGLIST="https://abf.openmandriva.org/openmandriva/iso-pkg-lists/archive/iso-pkg-lists-${TREE,,}.tar.gz"
	$SUDO  wget --tries=10 -O `echo "$WORKDIR/iso-pkg-lists-${TREE,,}.tar.gz"` --content-disposition $PKGLIST
	$SUDO tar zxfC $WORKDIR/iso-pkg-lists-${TREE,,}.tar.gz $WORKDIR
	$SUDO tar zxfC $WORKDIR/iso-pkg-lists-master.tar.gz $WORKDIR
	# Why not retain the unique list name it will help when people want their own spins ?
	$SUDO rm -f iso-pkg-lists-master.tar.gz
	# Finally get an md5checksum for the package list dir so it can be conditionally re-processed on local builds
    fi

    printf "%s\n -> Your ISO has a modified filelist"

    # export file list
    FILELISTS="$WORKDIR/iso-pkg-lists-${TREE,,}/${DIST,,}-${TYPE,,}.lst"


    if [ ! -e "$FILELISTS" ]; then
	printf "%s\n -> $FILELISTS does not exist. Exiting"
	errorCatch
    fi
}

showInfo() {

	echo $'###\n'
	printf "%s\n Building ISO with arguments:"
	printf "%s\n Distribution is $DIST"
	printf "%s\n Architecture is $EXTARCH"
	printf "%s\n Tree is $TREE"
	printf "%s\n Version is $VERSION"
	printf "%s\n Release ID is $RELEASE_ID"
	printf "%s\n Type is $TYPE"
	if [ "${TYPE,,}" = "minimal" ]; then
	    printf "%s\n No display manager for minimal ISO."
	else
	    printf "%s\n Display Manager is $DISPLAYMANAGER"
	fi
	printf "%s\n ISO label is $LABEL"
	printf "%s\n Build ID is $BUILD_ID"
	printf "%s\n Working directory is $WORKDIR"
	if  [ -n "$REBUILD" ]; then
	    printf "%s\n All rpms will be re-installed"
	elif [ -n "$NOCLEAN" ]; then
	    printf "%s\n Installed rpms will be updated"
	fi
	if [ -n "$DEBUG" ]; then
	    printf "%s\n Debugging enabled"
	fi
	if [ -n "$QUICKEN" ]; then
	    printf "%s\n Squashfs compression disabled"
	fi
	if [ -n "$KEEP" ]; then
	    printf "%s\n The session diffs will be retained"
	fi
	if [ -n "$ENSKPLST" ]; then
        printf "%\n urpmi skip list enabled"
    fi
	printf "%s\n ### %s\n"
}

localMd5Change() {
# Usage: userMd5Change [VARNAME] {Name of variable to contain diff list}
# Function:
# Creates md5sums current iso package list directory and store to file if file does not already exist.
# Three files are created "$WORKDIR/filesums", "/tmp/filesums" and $WORKDIR/chngsense
# The first two contain file md5's for the original set and the current set, the last contains the checksum for the entire directory.
# On each run the directory md5sums are compared if there has been a change a flag is set triggering modification of the chroot.
# If the flag is set the md5s for the files are compared and a named variable containing the changed files is emmitted.
# This variable is used as input for diffPkgLists() to generate diffs for the information of the developer/user
	BASE_LIST=$WORKDIR/iso-pkg-lists-${TREE}
#    if [ "$IN_ABF" == "0" ]; then
	local __dodiff='diff --suppress-common-lines --unchanged-group-format=\"\" --changed-group-format=\""%>\""'
	local __difflist
        if [ ! -d "$WORKDIR/sessrec" ]; then
        mkdir -p "$WORKDIR/sessrec"
    #		fi
    #		if [ -f $WORKDIR/.new ]; then
        echo $'\n'
        printf "%s\n -> Making directory reference sum"
        REF_CHGSENSE=`$SUDO md5sum ${BASE_LIST}/* | colrm 33 | md5sum | tee "$WORKDIR"/sessrec/ref_chgsense`
        printf "%s\n -> Making reference file sums"
        REF_FILESUMS=`$SUDO find ${BASE_LIST}/*  -type f   -exec md5sum {} \; | tee $WORKDIR/sessrec/ref_filesums`
            if [ -n "$DEBUG" ]; then
            printf "%s\n $REF_CHGSENSE %s\n"
            printf "%s\n $REF_FILESUMS %s\n"
            fi
        else
        REF_CHGSENSE=`cat "$WORKDIR"/sessrec/ref_chgsense`
	    REF_FILESUMS=`cat "$WORKDIR"/sessrec/ref_filesums`
	    printf "%s\n -> References loaded"
#        fi
	# Generate the references for this run
	# Need to be careful here; there may be backup files so get the exact files
	# Order is important (sort?)
	NEW_CHGSENSE=`$SUDO md5sum  $BASE_LIST/my.add $BASE_LIST/my.rmv $BASE_LIST/*.lst | colrm 33 | md5sum | tee "$WORKDIR"/sessrec/new_chgsense`
	NEW_FILESUMS=`$SUDO find ${BASE_LIST}/* -type f -exec md5sum {} \; | tee $WORKDIR/sessrec/new_filesums`
	printf "%s\n -> New references created %s\n"
	fi
    if [ -n "$DEBUG" ]; then
    printf "%s\n Directory Reference checksum $REF_CHGSENSE %s\n"
    printf "%s\n Reference Filesums %s\n$REF_FILESUMS %s\n"
    printf "%s\n New Directory Reference checksum $NEW_CHGSENSE %s\n"
    printf "%s\n New Filesums %s\n$NEW_FILESUMS%s\n"
    fi
    
    if [ -f "$WORKDIR/sessrec/ref_chgsense" ]; then
        if [ "$NEW_CHGSENSE" == "$REF_CHGSENSE" ]; then
        CHGFLAG=0
        else
        $SUDO echo "$NEW_CHGSENSE" >"$WORKDIR"/sessrec/ref_chgsense
        CHGFLAG=1
        fi
    fi
	if [ "$CHGFLAG" == "1" ]; then
	    printf "%s\n -> Your build files have changed"
	fi

# Create a list of changed files by diffing checksums
# In these circumstances awk does a better job than diff
# This looks complicated but all it does is to put the two fields in each file into independent arrays,
# compares the first field from each file and if they are not equal then print the second field (filename) from each file.
    MODFILES=`awk 'NR==FNR{c[NR]=$2; d[NR]=$1;next}; {e[FNR]=$1; f[FNR]=$2}; {if(e[FNR] == d[FNR]){} else{print c[FNR],"   "f[FNR]}}' "$WORKDIR/sessrec/ref_filesums" "$WORKDIR/sessrec/new_filesums"`
    USERMOD=`printf '%s' "$MODFILES" | grep 'my.add\|my.rmv'`
    if [ -z "$USERMOD" ]; then
        printf "%s\n -> No Changes"
    else
        printf "%s\n $USERMOD"
    fi
    # Here just the standard files are diffed ommitting my.add and my.remove
    # Intended for developers creating new compilations only active if --debug is passed 
    DEVMOD=`printf '%s' "$MODFILES" | grep -v 'my.add\|my.rmv'`
# This list is intended for Developers
    if [ "$CHGFLAG" == "1" ] && [ -n "$DEBUG" ] && [ -n "$DEVMOD" ]; then #&& DEVMOD NOT EMPTY THEN RUN A FULL UPDATE NOT JUST ADD AND REMOVE
# Create a developer diff ommitting my.add and my.rmv
        diffPkgLists "$DEVMOD"
    elif [ "$CHGFLAG" == "1" ]; then
# Create a diff for the users reference
        diffPkgLists "$USERMOD"
    fi
 }

getIncFiles() {
# Usage: getIncFiles [filename] xyz.* $"[name of variable to return] [package list file. my.add || my.rmv || {main config pkgs}]
# Function: Gets all the include lines for the specified package file
# The full path to the package list must be supplied

# Set 'lastpipe' options so as not to lose variable in sub-shells.
    set +m
    shopt -s lastpipe
#set -x
# Define a some local variables
    local __infile=$1   # The main build file
    local __incflist=$2 # Carries returned variable

# Recursively fetch included files
    while read -r  r; do
	[ -z "$r" ] && continue
	__addrpminc+="$__addrpminc"$'\n'"$WORKDIR"/iso-pkg-lists-"$TREE"/"$r"
	getIncFiles $(dirname "$1")/"$r" "$2" "$3"
	continue
# Avoid sub-shells make sure commented out includes are removed.
    done < <(cat "$1" | grep  '^[A-Za-z0-9 \t]*%include' | sed '/ #/d' | awk -F\./// '{print $2}' | sed '/^\s$/d' | sed '/^$/d')
#  Add the primary file to the list
    __addrpminc+=$'\n'"$1"
    # Sort so the main file is at the top and export
    # Note this functionality allows us to combine package lists that may contain duplicates
    __addrpminc=`echo "$__addrpminc" | sort -u | sed -n '/^$/!p'`
    eval $__incflist="'$__addrpminc'"
    shopt -u lastpipe
    set -m
}

createPkgList() {
# Usage: createPkgList  "$VAR" VARNAME
# Function: Creates lists of packages from package lists
# VAR: A variable containing a list of package lists
# VARNAME: A variable name to identify the returned list of packages.
# Intent: Can be used to generate named variables
# containing packages to install or remove.

# NOTE: This routine requires 'lastpipe' so that
# subshells do not dump their data.
# This requires that job control be disabled.
    set +m
    shopt -s lastpipe
#set -x
# Define a local variable to hold user VAR
    local __pkglist=$2 # Carries returned variable name
# other locals not needed outside routine
    local __pkgs # The list of packages
    local __pkglst # The current package list
    while read -r __pkglst; do
	#__pkgs+=$'\n'`cat "$__pkglst"`
    __pkgs+=$'\n'`cat "$__pkglst" 2> /dev/null`  
    done < <(printf '%s\n' "$1") 
# sanitise regex compliments of TPG
    __pkgs=`printf '%s\n' "$__pkgs" | grep -v '%include' | sed -e 's,        , ,g;s,  *, ,g;s,^ ,,;s, $,,;s,#.*,,' | sed -n '/^$/!p' | sed 's/ $//'`
    #The above was getting comments that occured after the package name i.e. vim-minimal #mini-iso9660. but was leaving a trailing space which confused parallels and it failed the install

    eval $__pkglist="'$__pkgs'"
    if [ -n "$DEBUG" ]; then
	printf  "%s\n -> This is the $2 package list"
	printf "%s\n $__pkgs"
	$SUDO printf '%s' "$__pkgs" >$WORKDIR/$2.list
    fi

    shopt -u lastpipe
    set -m
}


diffPkgLists() {
# Usage verifyPkgLists $(LIST_VARIABLE)
# The "LIST VARIABLE" contains a 'side by side' list of filenames to be diffed.
# Compares the users set of rpm lists with the shipped set
# Intent. Used to determine whether changes have occurred in the users set of rpm lists.
# Diffs are numbered sequentially each time the script is run with --noclean or --rebuild set
# The primary name of the diff is derived from the $WORKDIR thus the diffs remain in context with the session.
# The diffs generated are culmulative which means that each diff is the sum of all the previous diffs
# thus each diff created contains the entire record of the session.
# Running without --noclean set destroys the $WORKDIR and thus the diffs.
# Adding the --keep flag will move the diffs to the users home directory. They will be moved back at
# the start of each new session if the --keep flag is set and --noclean or --rebuild are selected.
    if [ "$IN_ABF" == "0" ]; then
	local __difflist=$1
	local dodiff="/usr/bin/diff -Naur"

	if [ -f "$WORKDIR"/sessrec/.seqnum ]; then
	    SEQNUM=`cat "$WORKDIR"/sessrec/.seqnum`
	else
	    SEQNUM=1
	    $SUDO echo $SEQNUM >"$WORKDIR"/sessrec/.seqnum
	fi
# Here a combined diff is created
	while read -r DIFF ; do
	    ALL+=`eval  "$dodiff" "$DIFF"`$'\n'
	done < <(printf '%s\n' "$__difflist")

	if [ -d "$WORKDIR/sessrec" ]; then
# Here the old diff is compared with the new if it exists
	    local __lastdiffname=$(basename "$WORKDIR")"$SEQNUM".diff
	    if [ -s $__lastdiffname ]; then
		diff -y <(printf %s "$ALL")  "$WORKDIR"/sessrec/"$__lastdiffname"
		local __same=$?
# Here we save the diff but only if it's different from the previous one
		if [ $__same -eq 1 ]; then
		    SEQNUM=`echo $((SEQNUM+1))`
		    local __newdiffname=$(basename "$WORKDIR")"$SEQNUM".diff
		    $SUDO echo "$ALL" >"$WORKDIR"/sessrec/"$__newdiffname"
		    $SUDO echo "$SEQNUM" >"$WORKDIR"/sessrec/.seqnum
		elif [ $__same -eq 2 ]; then
	    printf  "%s\n -> Diff has reported an error %s\n -> Your files may be corrupted %s\n"
		fi
	    else
# Here no previous diff existed; so write the first one
		local __newdiffname=$(basename "$WORKDIR")"$SEQNUM".diff
		$SUDO echo "$ALL" >"$WORKDIR"/sessrec/"$__newdiffname"
		SEQNUM=`echo $((SEQNUM+1))`
		$SUDO echo $SEQNUM >"$WORKDIR"/sessrec/.seqnum
	    fi
	fi
    fi
}

mkOmSpin() {
# Usage: mkOmSpin [main install file path} i.e. [path]/omdv-kde4.lst.
# Returns a variable "$INSTALL_LIST" containing all rpms
# to be installed
    getIncFiles "$FILELISTS" ADDRPMINC
    printf '%s' "$ADDRPMINC" >"$WORKDIR/inclist"
    printf "%s -> Creating OpenMandriva spin from $FILELISTS %s\n Which includes %s\n"
    printf  "$ADDRPMINC" | grep -v "$FILELISTS"  
    createPkgList "$ADDRPMINC" INSTALL_LIST
    if [ -n "$DEVMODE" ]; then
    printf '%s' "$INSTALL_LIST" >"$WORKDIR/rpmlist"
    fi
    mkUpdateChroot "$INSTALL_LIST"
}

updateUserSpin() {
# updateUserSpin [main install file path] i.e. path/omdv-kde4.lst
# Sets two variables
# INSTALL_LIST = All list files to be installed
# REMOVE_LIST = All list files to be removed
# This function only updates using the user my.add and my.rmv files.
# It is used to add user updates after the main chroot
# has been created with mkUserSpin.
    printf "%s\n -> Updating user spin %s\n"
    getIncFiles "$WORKDIR/iso-pkg-lists-$TREE/my.add" UADDRPMINC my.add
# re-assign just for consistancy
    ALLRPMINC=`echo "$UADDRPMINC"`
    getIncFiles "$WORKDIR/iso-pkg-lists-$TREE/my.rmv" PRE_RMRPMINC  my.rmv
# "Remove any duplicate includes"
    RMRPMINC=`comm -1 -3 <(printf '%s\n' "$ALLRPMINC" | sort ) <(printf '%s\n' "$PRE_RMRPMINC" | sort)`
    createPkgList "$ALLRPMINC" INSTALL_LIST
    createPkgList "$RMRPMINC" REMOVE_LIST
	printf "%s/n -> This is the include list %s\n"
	printf "%s/n $ALLRPMINC"
	printf "%s\n\n -> This is the remove incfile list %s\n"
	printf "%s $RMRPMINC"
	if [ -n "$DEVMODE" ]; then
	$SUDO printf '%s\n' "$ALLRPMINC" >$WORKDIR/add_incfile.list
	#	printf '%s\n\n' " "
	$SUDO printf '%s\n' "$RMRPMINC" >$WORKDIR/remove_incfile.list
    fi
# "Remove any packages that occur in both lists"
#    REMOVE_LIST=`comm -1 -3 --nocheck-order <(printf '%s\n' "$INSTALL_LIST" | sort) <(printf '%s\n' "$PRE_REMOVE_LIST" | sort)`
printf "$REMOVE_LIST"
    if [ -n "$DEVMODE" ]; then
	$SUDO printf '%s\n' "$INSTALL_LIST" >"$WORKDIR/user_update_add_rpmlist"
	$SUDO printf '%s\n' "$REMOVE_LIST" >"$WORKDIR/user_update_rm_rpmlist"
    fi
#    mkUpdateChroot  "$INSTALL_LIST" "$REMOVE_LIST"
        printf "%s\n "$INSTALL_LIST" %s\n $REMOVE_LIST"
        errorCatch
}

mkUserSpin() {
# mkUserSpin [main install file path} i.e. [path]/omdv-kde4.lst
# Sets two variables
# $INSTALL_LIST = All list files to be installed
# $REMOVE_LIST = All list files to be removed
# This function includes all the user adds and removes.
#set -x
#printf "%s $CHGFLAG %s\n"
#    echo $'\n'
    printf "%s -> Making a user spin"
    if [ "$CHGFLAG" == "0" ]; then
    getIncFiles "$FILELISTS" ADDRPMINC $TYPE
    else
    getIncFiles $WORKDIR/iso-pkg-lists-$TREE/my.add UADDRPMINC my.add
    ALLRPMINC=`echo "$ADDRPMINC"$'\n'"$UADDRPMINC" | sort -u`
    printf "%s\n $ALLRPMINC %s\n" > "$WORKDIR/primary.list"
    getIncFiles $WORKDIR/iso-pkg-lists-$TREE/my.rmv PRE_RMRPMINC  my.rmv
    printf "%s\n -> Remove the common include lines for the remove package includes %s\n"
    RMRPMINC=`comm -1 -3 <(printf '%s\n' "$ALLRPMINC" | sort ) <(printf '%s\n' "$PRE_RMRPMINC" | sort)`
    printf "%s -> Creating $WHO's OpenMandriva spin from $FILELISTS %s\n Which includes"
    printf '%s\n' "$ALLRPMINC" | grep -v "$FILELISTS"
    fi
    # Create the package lists
    createPkgList "$ALLRPMINC" INSTALL_LIST
    createPkgList "$RMRPMINC" REMOVE_LIST
# Then to be sure remove the common lines from the remove package lists
    #REMOVE_LIST=`comm -1 -3 --nocheck-order <(printf '%s\n' "$INSTALL_LIST" | sort) <(printf '%s\n' "$PRE_REMOVE_LIST" | sort)`
    if [ -n "$DEVMODE" ]; then
	$SUDO printf '%s\n' "$INSTALL_LIST" >"$WORKDIR/user_add_rpmlist"
	$SUDO printf '%s\n' "$REMOVE_LIST" >"$WORKDIR/user_rm_rpmlist"
    fi
    mkUpdateChroot "$INSTALL_LIST" "$REMOVE_LIST"
}

mkUpdateChroot() {
# Usage: mkUpdateChroot [Install variable] [remove variable] [update type]
# Function:      If the --noclean option is set and a full chroot has been built
#               (presence of .noclean in the chroot directory) then this function will be
#               called when a change is detected in the users iso-build-lists.
#               If the rebuild flag is set the entire chroot will be rebuilt using
#               the main and user created configurations lists.
#               It will first add any specified packages to the current chroot
#               and then remove the specified packages using the auto-orphan option
#               if the variable is not empty.
#               As a minimum the INSTALL_LIST must exist in the environment.
#               The optional REMOVE_LIST  can also be supplied.
#               These variables must contain lists of newline
#               separated package names for installation or removal.
#               The variable names are flexible but their content and order on the commandline
#               are mandatory.
	printf "%s\n -> Updating chroot %s\n"
	local __install_list="$1"
	local __removelist="$2"

	if [ -n "$REBUILD" ]; then
	    printf "%s\n Reloading saved rpms %s\n"
	    # Can't take full advantage of parallel until a full rpm dep list is produced which means using a solvedb setup. We can however make use of it's fail utility..Add some logging too
	    printf '%s\n' "$__install_list" | parallel -q --keep-order --joblog "$WORKDIR/install.log" --tty --halt now,fail=10 -P 1 /usr/sbin/urpmi --noclean --urpmi-root "$CHROOTNAME" --no-suggests --fastunsafe --ignoresize --nolock --auto ${URPMI_DEBUG}
	elif [ "$CHGFLAG" == "1" ] && [ -d "$CHROOTNAME/lib/modules" ] && [ -n "$1" ] && [ -n "$NOCLEAN" ]; then
        printf "%s\n -> Installing user package selection %s\n"
	    printf '%s\n' "$__install_list" | parallel -q --keep-order --joblog "$WORKDIR/install.log" --tty --halt now,fail=10 -P 1 /usr/sbin/urpmi --noclean --urpmi-root "$CHROOTNAME" --download-all --no-suggests --fastunsafe --ignoresize --nolock --auto ${URPMI_DEBUG} 2>$WORKDIR/missing
	    $SUDO printf '%s\n' "$__install_list" >"$WORKDIR/RPMLIST.txt"
    elif [ -n "$1" ] && [ "$IN_ABF" == "1" ]; then #Use xargs for ABF just in case of any unexpected interactions
	    printf "%s\n -> Installing packages at ABF %s\n"
	    #printf "$__install_list %s\n"
	    #Strip the newlines
	    #printf "$__install_list" | tr '\n' ' ' | xargs -n 1 $SUDO /usr/sbin/urpmi --noclean --urpmi-root "$CHROOTNAME" --download-all --no-suggests --fastunsafe --ignoresize --nolock --auto ${URPMI_DEBUG} >  "$WORKDIR/xargs_debug"
	    printf "$__install_list" | xargs -n 1 $SUDO /usr/sbin/urpmi --noclean --urpmi-root "$CHROOTNAME" --download-all --no-suggests --fastunsafe --ignoresize --nolock --auto ${URPMI_DEBUG} >  "$WORKDIR/xargs_debug"
    elif [ -n "$1" ] && [ -z "$NOCLEAN" ] && [ -z "$REBUILD" ] && [ "$IN_ABF" == "0" ]; then
        printf "%s\n -> Installing packages locally %s\n"
        printf '%s\n' $__install_list | parallel -q --keep-order -d '\n' --joblog "$WORKDIR/install.log"  --tty --halt now,fail=10 -P 1 /usr/sbin/urpmi --noclean --urpmi-root "$CHROOTNAME" --download-all --no-suggests --fastunsafe --ignoresize --nolock --auto ${URPMI_DEBUG} 
	else
	    printf "%s\n No rpms need to be installed %s\n" 
	fi

	if [ "$CHGFLAG" == "1" ] && [ -d "$CHROOTNAME/lib/modules" ] && [ -n "$2" ] && [ -n "$NOCLEAN" ]; then
	printf "%s -> Removing user specified rpms and orphans %s\n"
# rpm is used here to get unconditional removal. urpme's idea of a broken system does not comply with our minimal install.
	    printf '%s\n' "$__removelist" | parallel --tty --halt now,fail=10 -P 1 $SUDO rpm -e -v --nodeps --noscripts --dbpath "$CHROOTNAME/var/lib/rpm"
# This exposed a bug in urpme
	    $SUDO urpme --urpmi-root "$CHROOTNAME"  --auto --auto-orphans --force
	    #printf '%s\n' "$__removelist" | parallel --dryrun --halt now,fail=10 -P 6  "$SUDO" urpme --auto --auto-orphans --urpmi-root "$CHROOTNAME"
	else
	    printf "%s\n No rpms need to be removed %s\n"
	fi
	if [ "$IN_ABF" == "0" ] && [ -f "$WORKDIR/install.log" ]; then
        #Make some helpful logs
        #Create the header
        head -1 $WORKDIR/install.log >$WORKDIR/rpm-fail.log
        head -1 $WORKDIR/install.log >$WORKDIR/rpm-install.log
        #Append the data
        cat "$WORKDIR/install.log" | awk '$7  ~ /1/' >> "$WORKDIR/rpm-fail.log"
        cat "$WORKDIR/install.log" | awk '$7  ~ /0/' >> "$WORKDIR/rpm-install.log"
        #Clean-up
        rm -f "$WORKDIR/install.log"
    fi
}

createChroot() {
# Usage: createChroot packages.lst /target/dir
# Creates a chroot environment with all packages in the packages.lst
# file and their dependencies in /target/dir

if [ "CHGFLAG" != "1" ]; then
    REPOPATH="http://abf-downloads.openmandriva.org/${TREE,,}/repository/$EXTARCH/"
    echo $'\n'
    if [ -f "$CHROOTNAME"/.noclean ] && [ ! -d "$CHROOTNAME/lib/modules" ] || [ -n "$REBUILD" ]; then 
    printf "%s\n -> Creating chroot "$CHROOTNAME" %s\n"
    else 
    printf "%s\n -> Updating existing chroot "$CHROOTNAME" %s\n"
    fi
# Make sure /proc, /sys and friends are mounted so %post scripts can use them
    $SUDO mkdir -p "$CHROOTNAME/proc" "$CHROOTNAME/sys" "$CHROOTNAME/dev" "$CHROOTNAME/dev/pts"
#    exit
# Do not clean build chroot
    if [ -n "$NOCLEAN" ] && [ ! -f "$CHROOTNAME/.noclean" ]; then
        touch "$CHROOTNAME/.noclean"
	fi

    if [ -n "$REBUILD" ] && [ -z "$NOCLEAN" ]; then
	ANYRPMS=`find "$CHROOTNAME/var/cache/urpmi/rpms/" -name "basesystem-minimal*.rpm"  -type f  -printf %f`
        if [ -z "$ANYRPMS" ]; then
            printf "%s\n -> You must run with --noclean before you use --rebuild %s\n"
            errorCatch
        fi
	else
    printf "%s\n -> Rebuilding. %s\n"
	fi
fi

# If chroot exists and if we have --noclean then the repo files are not needed with exception of the
# first time run with --noclean when they must be installed. If --rebuild is called they will have been
# deleted so reinstall them. 
printf "%s $REPOPATH"
# If the kernel hasn't been installed then it's a new chroot or a rebuild
    if [ ! -d "$CHROOTNAME"/lib/modules ] || [ -n "$REBUILD" ]; then
	printf "%s -> Adding urpmi repository $REPOPATH into $CHROOTNAME"
        if [ "$FREE" = "0" ]; then
        $SUDO urpmi.addmedia --wget --urpmi-root "$CHROOTNAME" --distrib $REPOPATH
        else
        $SUDO urpmi.addmedia --wget --urpmi-root "$CHROOTNAME" "Main" $REPOPATH/main/release
        $SUDO urpmi.addmedia --wget --urpmi-root "$CHROOTNAME" "Contrib" $REPOPATH/contrib/release
        # This one is needed to grab firmwares
        $SUDO urpmi.addmedia --wget --urpmi-root "$CHROOTNAME" "Non-free" $REPOPATH/non-free/release
        fi
        if [ "${TREE,,}" != "cooker" ]; then
        $SUDO urpmi.addmedia --wget --urpmi-root "$CHROOTNAME" "MainUpdates" $REPOPATH/main/updates
        $SUDO urpmi.addmedia --wget --urpmi-root "$CHROOTNAME" "ContribUpdates" $REPOPATH/contrib/updates
    # This one is needed to grab firmwares
        $SUDO urpmi.addmedia --wget --urpmi-root "$CHROOTNAME" "Non-freeUpdates" $REPOPATH/non-free/updates
            if [ -n "$TESTREPO" ]; then
            $SUDO urpmi.addmedia --wget --urpmi-root "$CHROOTNAME" "MainTesting" $REPOPATH/main/testing
            fi
        fi
	fi

# Update media

    SKIPLISTS="$WORKDIR/iso-pkg-lists-${TREE,,}/skip.lst"
    echo "This is the skip list $SKIPLISTS"
 
    $SUDO urpmi.update -a -c -ff --wget --urpmi-root "$CHROOTNAME" main
    if [ "${TREE,,}" != "cooker" ]; then
	printf "%s -> Updating urpmi repositories in $CHROOTNAME"
	$SUDO urpmi.update -a -c -ff --wget --urpmi-root "$CHROOTNAME" updates
    fi
    if [ -n "$ENSKPLST" ]; then
    SKIPLISTS="$WORKDIR/iso-pkg-lists-${TREE,,}/skip.lst"
    echo "This is the skip list $SKIPLISTS"
    $SUDO cp "$SKIPLISTS" "$CHROOTNAME/etc/urpmi/"
    printf "%s\n Installing urpmi skip.list"
    fi

    $SUDO mount --bind /proc "$CHROOTNAME"/proc
    $SUDO mount --bind /sys "$CHROOTNAME"/sys
    $SUDO mount --bind /dev "$CHROOTNAME"/dev
    $SUDO mount --bind /dev/pts "$CHROOTNAME"/dev/pts
printf "%s\n Done Mounting proc and friends %s\n"
# Start rpm packages installation but only if .noclean does not exist and CHGFLAG=0
# CHGFLAG=1 Indicates a global change in the iso lists
# If we are IN_ABF and neither --noclean or --rebuild are set then build a standard iso without the uses package lists.
# If --noclean is set and debug is not set and its the first time --noclean is run 
# i.e. (.noclean file in chroot does not exist) then make a spin including the user filelists.
# if --rebuild is set then make a spin with the user filelists
# If --noclean is set and a change in the filelists has been detected and we are not in_abf 
# then update the  user spin with the users modified filelists.
echo "$DEVMODE"
    if [ -z "$NOCLEAN" ] && [ -z "$REBUILD" ]; then
    printf "%s\n Creating chroot %s\n"
	mkOmSpin
    elif [ -n "$NOCLEAN" ] && [ ! -f "$CHROOTNAME"/.noclean ] && [ -v "$DEBUG" ] && [ -v "$DEVMODE" ]; then
    mkOmSpin
    elif [ -n "$NOCLEAN" ] && [ -f "$CHROOTNAME"/.noclean ] && [ -v "$DEBUG" ] && [ -v "$DEVMODE" ]; then
    mkUserSpin $FILELISTS
    elif [ -n "$REBUILD" ]; then
    printf  "%s\n -> Rebuilding. %s\n"
    mkUserSpin $FILELISTS
    elif [ -f "$CHROOTNAME"/.noclean ] && [ "$CHGFLAG" == "1" ] && [ "$IN_ABF" == "0" ] && [ -n "$USERMODE" ]; then
    updateUserSpin "$FILELISTS"
	# This functionality will only update the build if there is a change in files
    # other then my.add and my.rmv
	elif [ "$CHGFLAG" == "1" ] && [ "$IN_ABF" == "0" ] && [ -n "$USERMODE" ]; then
        mkUserSpin $FILELISTS
    #Allow an unconditional update irrespective of CHNGFLAG or NOCLEAN state.
   	elif [ "$IN_ABF" == "0" ] && [ -n "$DEVMODE" ]; then
   	mkOmSpin $FILELISTS
    fi
    if [ -n "$REBUILD" ]; then
    # Restore the noclean status
	$SUDO touch "$CHROOTNAME/.noclean"
    fi
    if [[ $? != 0 ]] && [ ${TREE,,} != "cooker" ]; then
	printf "%s\n -> Can not install packages from $FILELISTS"
	errorCatch
    fi
    # If --noclean selected mark the chroot
    if [ -n "$NOCLEAN" ]; then
	touch "$CHROOTNAME"/.noclean
    fi
# Check CHROOT
    if [ ! -d  "$CHROOTNAME"/lib/modules ]; then
	printf "%s\n -> Broken chroot installation. Exiting %s\n"
	errorCatch
    fi
# Export installed and boot kernel
    pushd "$CHROOTNAME"/lib/modules
    BOOT_KERNEL_ISO=`ls -d --sort=time [0-9]*-${BOOT_KERNEL_TYPE}* | head -n1 | sed -e 's,/$,,'`
    export BOOT_KERNEL_ISO
    if [ -n "$BOOT_KERNEL_TYPE" ]; then
	$SUDO echo $BOOT_KERNEL_TYPE > "$CHROOTNAME"/boot_kernel
	KERNEL_ISO=`ls -d --sort=time [0-9]* | grep -v $BOOT_KERNEL_TYPE | head -n1 | sed -e 's,/$,,'`
    else
	KERNEL_ISO=`ls -d --sort=time [0-9]* |head -n1 | sed -e 's,/$,,'`
    fi
    export KERNEL_ISO
    popd
# remove rpm db files which may not match the target chroot environment
    $SUDO chroot "$CHROOTNAME" rm -f /var/lib/rpm/__db.*
set +x
}

createInitrd() {
# Check if dracut is installed
    if [ ! -f "$CHROOTNAME"/usr/sbin/dracut ]; then
	printf "%s\n -> dracut is not installed inside chroot. Exiting."
	errorCatch
    fi

# Build initrd for syslinux
    printf "%s\n -> Building liveinitrd-$BOOT_KERNEL_ISO for ISO boot %s\n"
    if [ ! -f "$WORKDIR"/dracut/dracut.conf.d/60-dracut-isobuild.conf ]; then
	printf "%s\n -> Missing "$WORKDIR"/dracut/dracut.conf.d/60-dracut-isobuild.conf . Exiting."
	errorCatch
    fi

    $SUDO cp -f "$WORKDIR"/dracut/dracut.conf.d/60-dracut-isobuild.conf "$CHROOTNAME"/etc/dracut.conf.d/60-dracut-isobuild.conf

    if [ ! -d "$CHROOTNAME"/usr/lib/dracut/modules.d/90liveiso ]; then
	printf "%s\n -> Dracut is missing 90liveiso module. Installing it. %s\n"

	if [ ! -d "$WORKDIR"/dracut/90liveiso ]; then
	    printf "%s\n -> Cant find 90liveiso dracut module in $WORKDIR/dracut. Exiting."
	    errorCatch
	fi

	$SUDO cp -a -f "$WORKDIR"/dracut/90liveiso "$CHROOTNAME"/usr/lib/dracut/modules.d/
	$SUDO chmod 0755 "$CHROOTNAME"/usr/lib/dracut/modules.d/90liveiso
	$SUDO chmod 0755 "$CHROOTNAME"/usr/lib/dracut/modules.d/90liveiso/*.sh
    fi

# Fugly hack to get /dev/disk/by-label
    $SUDO sed -i -e '/KERNEL!="sr\*\", IMPORT{builtin}="blkid"/s/sr/none/g' -e '/TEST=="whole_disk", GOTO="persistent_storage_end"/s/TEST/# TEST/g' "$CHROOTNAME"/lib/udev/rules.d/60-persistent-storage.rules
    if [[ $? != 0 ]]; then
	printf "%s\n -> Failed with editing /lib/udev/rules.d/60-persistent-storage.rules file. Exiting."
	errorCatch
    fi

    if [ -f "$CHROOTNAME"/boot/liveinitrd.img ]; then
	$SUDO rm -rf "$CHROOTNAME"/boot/liveinitrd.img
    fi

# Set default plymouth theme
    if [ -x "$CHROOTNAME"/usr/sbin/plymouth-set-default-theme ]; then
	chroot "$CHROOTNAME" /usr/sbin/plymouth-set-default-theme OpenMandriva
    fi

# Building liveinitrd
    $SUDO chroot "$CHROOTNAME" /usr/sbin/dracut -N -f --no-early-microcode --nofscks --noprelink  /boot/liveinitrd.img --conf /etc/dracut.conf.d/60-dracut-isobuild.conf $KERNEL_ISO

    if [ ! -f "$CHROOTNAME"/boot/liveinitrd.img ]; then
	printf "%s\n -> File $CHROOTNAME/boot/liveinitrd.img does not exist. Exiting. %s\n"
	errorCatch
    fi

    printf "%s\n -> Building initrd-$KERNEL_ISO inside chroot %s\n"
# Remove old initrd
    $SUDO rm -rf "$CHROOTNAME/boot/initrd-$KERNEL_ISO.img"
    $SUDO rm -rf "$CHROOTNAME"/boot/initrd0.img

# Remove config before building initrd
    $SUDO rm -rf "$CHROOTNAME"/etc/dracut.conf.d/60-dracut-isobuild.conf
    $SUDO rm -rf "$CHROOTNAME"/usr/lib/dracut/modules.d/90liveiso

# Building initrd
    $SUDO chroot "$CHROOTNAME" /usr/sbin/dracut -N -f "/boot/initrd-$KERNEL_ISO.img" "$KERNEL_ISO"
    if [[ $? != 0 ]]; then
	printf "%s\n -> Failed creating initrd. Exiting."
	errorCatch
    fi

# Build the boot kernel initrd in case the user wants it kept
    if [ -n "$BOOT_KERNEL_TYPE" ]; then
# Building boot kernel initrd
        printf "%s\n -> Building initrd-$BOOT_KERNEL_ISO inside chroot %s\n"
        $SUDO chroot "$CHROOTNAME" /usr/sbin/dracut -N -f "/boot/initrd-$BOOT_KERNEL_ISO.img" "$BOOT_KERNEL_ISO"
	if [[ $? != 0 ]]; then
	    printf "%s\n -> Failed creating boot kernel initrd. Exiting."
	    errorCatch
	fi
    fi

    $SUDO ln -sf /boot/initrd-$KERNEL_ISO.img "$CHROOTNAME"/boot/initrd0.img

}

createMemDisk () {
# Usage: createMemDIsk <target_directory/image_name>.img <grub_support_files_directory> <grub2 efi executable>
# Creates a fat formatted file ifilesystem image which will boot an UEFI system.

    if [ $EXTARCH = "x86_64" ]; then
	ARCHFMT=x86_64-efi
	ARCHPFX=X64
    else
	ARCHFMT=i386-efi
	ARCHPFX=IA32
    fi

    ARCHLIB=/usr/lib/grub/"$ARCHFMT"
    EFINAME=BOOT"$ARCHPFX".efi
    printf "%s\n -> Setting up UEFI partiton and image. %s\n"
    GRB2FLS="$ISOROOTNAME"/EFI/BOOT
# Create memdisk directory
    if [ -e "$WORKDIR"/boot/grub ]; then
	$SUDO /bin/rm -R "$WORKDIR"/boot/grub
	$SUDO mkdir -p "$WORKDIR"/boot/grub
    else
	$SUDO mkdir -p "$WORKDIR"/boot/grub
    fi
    MEMDISKDIR=$WORKDIR/boot/grub

# Copy the grub config file to the chroot dir for UEFI support
# Also set the uuid
    $SUDO cp -f "$WORKDIR"/grub2/start_cfg "$MEMDISKDIR"/grub.cfg
    $SUDO sed -i -e "s/%GRUB_UUID%/${GRUB_UUID}/g" "$MEMDISKDIR"/grub.cfg

# Ensure the old image is removed
    if [ -e "$CHROOTNAME"/memdisk_img ]; then
	$SUDO rm -f "$CHROOTNAME"/memdisk_img
    fi

# Create a memdisk img called memdisk_img
    cd "$WORKDIR" || exit
    tar cvf $CHROOTNAME/memdisk_img boot

# Make the image locally rather than rely on the grub2-rpm this allows more control as well as different images for IA32 if required
# To do this cleanly it's easiest to move the ISO directory containing the config files to the chroot, build and then move it back again
    $SUDO mv -f $ISOROOTNAME $CHROOTNAME

# Job done just remember to move it back again
    chroot "$CHROOTNAME"  /usr/bin/grub2-mkimage -O $ARCHFMT -d $ARCHLIB -m memdisk_img -o /ISO/EFI/BOOT/"$EFINAME" -p '(memdisk)/boot/grub' \
     search iso9660 normal memdisk tar boot linux part_msdos part_gpt part_apple configfile help loadenv ls reboot chain multiboot fat udf \
     ext2 btrfs ntfs reiserfs xfs lvm ata cat test echo multiboot multiboot2 all_video efifwsetup efinet font gfxmenu gfxterm gfxterm_menu \
     gfxterm_background gzio halt hfsplus jpeg mdraid09 mdraid1x minicmd part_apple part_msdos part_gpt part_bsd password_pbkdf2 png reboot \
     search search_fs_uuid search_fs_file search_label sleep tftp video xfs lua loopback regexp

# Move back the ISO filesystem after building the EFI image.
    $SUDO mv -f $CHROOTNAME/ISO/ $ISOROOTNAME

# Ensure the ISO image is clear
    if [ -e "$CHROOTNAME"/memdisk.img ]; then
	$SUDO rm -f "$CHROOTNAME"/memdisk_img
    fi
}

createUEFI() {
# Usage: createEFI $EXTARCH $ISOCHROOTNAME
# Creates a fat formatted file in filesystem image which will boot an UEFI system.
# PLEASE NOTE THAT THE ISO DIRECTORY IS TEMPORARILY MOVED TO THE CHROOT DIRECTORY FOR THE PURPOSE OF GENERATING THE GRUB IMAGE.
#set -x
    if [ $EXTARCH = "x86_64" ]; then
	ARCHFMT=x86_64-efi
	ARCHPFX=X64
    else
	ARCHFMT=i386-efi
	ARCHPFX=IA32
    fi
    ARCHLIB=/usr/lib/grub/"$ARCHFMT"
    EFINAME=BOOT"$ARCHPFX".efi
    printf "%s\n -> Setting up UEFI partiton and image. %s\n"

# Why doesn't this work on ABF
    IMGNME="$ISOROOTNAME"/boot/grub/"$EFINAME"
#        IMGNME="$ISOROOTNAME"/"$EFINAME"
    #IMGNME="$ISOROOTNAME"/boot/efi.img
    GRB2FLS="$ISOROOTNAME"/EFI/BOOT

    printf "%s\n -> Building GRUB's EFI image. %s\n"
    if [ -e $IMGNME ]; then
	$SUDO rm -rf $IMGNME
    fi
    FILESIZE=`du -s --block-size=512 "$ISOROOTNAME"/EFI | awk '{print $1}'`
    EFIFILESIZE=$(( FILESIZE * 2 ))
    PARTTABLESIZE=$(( (2*17408)/512 ))
    EFIDISKSIZE=$((  $EFIFILESIZE + $PARTTABLESIZE + 1 ))

# Create the image.
    printf "%s\n -> Creating EFI image with size $EFIDISKSIZE %s\n"

# mkfs.vfat can create the image and filesystem directly
    $SUDO mkfs.vfat -C -F 16 -s 1 -S 512 -M 0xFF $IMGNME $EFIDISKSIZE
# Loopback mount the image
    $SUDO losetup -f $IMGNME
    if [[ $? != 0 ]]; then
	printf "%s\n -> Failed to mount loopback image. Exiting."
	errorCatch
    fi

    sleep 1
    $SUDO mount -t vfat $IMGNME /mnt
    if [[ $? != 0 ]]; then
	printf "%s\n -> Failed to mount UEFI image. Exiting."
	errorCatch
    fi

# Copy the Grub2 files to the EFI image
    $SUDO mkdir -p /mnt/EFI/BOOT
    $SUDO cp -R "$GRB2FLS"/"$EFINAME" /mnt/EFI/BOOT/"$EFINAME"

# Unmout the filesystem with EFI image
    $SUDO umount /mnt
# Make sure that the image is copied to the ISOROOT
    $SUDO cp -f  "$IMGNME" "$ISOROOTNAME"
# Clean up
    $SUDO kpartx -d $IMGNME
# Remove the EFI directory
    $SUDO rm -R "$ISOROOTNAME"/EFI
    XORRISO_OPTIONS2=" --efi-boot $EFINAME -append_partition 2 0xef $IMGNME"
}

setupGrub2() {
# Usage: setupGrub2 (chroot directory (~/BASE) , iso directory (~/ISO), configdir (~/omdv-build-iso-<arch>)
# Sets up grub2 to boot /target/dir

    if [ ! -e "$CHROOTNAME"/usr/bin/grub2-mkimage ]; then
	printf "%s\n -> Missing grub2-mkimage in installation. %s\n"
	errorCatch
    fi

# BIOS Boot and theme support
# NOTE Themes are used by the EFI boot as well.
# Copy grub config files to the ISO build directory
# and set the UUID's
    $SUDO cp -f "$WORKDIR"/grub2/grub2-bios.cfg "$ISOROOTNAME"/boot/grub/grub.cfg
    $SUDO sed -i -e "s/%GRUB_UUID%/${GRUB_UUID}/g" "$ISOROOTNAME"/boot/grub/grub.cfg
    $SUDO cp -f "$WORKDIR"/grub2/start_cfg "$ISOROOTNAME"/boot/grub/start_cfg
    printf "%s\n -> Setting GRUB_UUID to ${GRUB_UUID} %s\n"
    $SUDO sed -i -e "s/%GRUB_UUID%/${GRUB_UUID}/g" "$ISOROOTNAME"/boot/grub/start_cfg
    if [[ $? != 0 ]]; then
	    printf "%s\n -> Failed to set up GRUB_UUID. %s\n"
	    errorCatch
	fi

# Add the themes, locales and fonts to the ISO build firectory
    if [ "${TYPE}" != "minimal" ]; then
	mkdir -p "$ISOROOTNAME"/boot/grub "$ISOROOTNAME"/boot/grub/themes "$ISOROOTNAME"/boot/grub/locale "$ISOROOTNAME"/boot/grub/fonts
	$SUDO cp -a -f "$CHROOTNAME"/boot/grub2/themes "$ISOROOTNAME"/boot/grub/
	$SUDO cp -a -f "$CHROOTNAME"/boot/grub2/locale "$ISOROOTNAME"/boot/grub/
	$SUDO cp -a -f "$CHROOTNAME"/usr/share/grub/*.pf2 "$ISOROOTNAME"/boot/grub/fonts/
	sed -i -e "s/title-text.*/title-text: \"Welcome to OpenMandriva Lx $VERSION ${EXTARCH} ${TYPE} BUILD ID: ${BUILD_ID}\"/g" "$ISOROOTNAME"/boot/grub/themes/OpenMandriva/theme.txt

	if [[ $? != 0 ]]; then
	    printf "%s\n -> Failed to update Grub2 theme."
	    errorCatch
	fi
    fi
# Fix up 2014.0 grub installer line...We don't have Calamares in 2014.
    if [ "${VERSION,,}" == openmandriva2014.0 ]; then
    $SUDO sed -i -e "s/.*systemd\.unit=calamares\.target/ install/g" "$ISOROOTNAME"/boot/grub/start_cfg
    fi

    printf "%s\n -> Building Grub2 El-Torito image and an embedded image. %s\n"

    GRUB_LIB=/usr/lib/grub/i386-pc
    GRUB_IMG=$(mktemp)

# Copy memtest
    $SUDO cp -rfT "$WORKDIR/extraconfig/memtest" "$ISOROOTNAME/boot/grub/memtest"
    $SUDO chmod +x "$ISOROOTNAME/boot/grub/memtest"
# To use an embedded image with our grub2 we need to make the modules available in the /boot/grub directory of the iso. The modules can't be carried in the payload of
# the embedded image as it's size is limited to 32kb. So we copy the i386-pc modules to the isobuild directory

    mkdir -p "$ISOROOTNAME/boot/grub/i386-pc"
    $SUDO cp -rf "$CHROOTNAME/usr/lib/grub/i386-pc" "$ISOROOTNAME/boot/grub/"

# Build the grub images in the chroot rather that in the host OS this avoids any issues with different versions of grub in the host OS especially when using local mode.
# this means cooker isos can be built on a local machine running a different version of OpenMandriva
# It requires that all the files needed to build the image must be within the chroot directory when the chroot command is invoked.
# Also we cannot write outside of the chroot so the images generated will remain in the chroot directory and will need to be removed before the squashfs is built
# these will be in /tmp and they are only small so leave them for the time being.
# If the entire ~/ISO director is copied to the chroot we do do have to worry too much about hacking the existing script to work
# with new paths we can simple add the $CHROOTNAME to the $ISOCHROOTNAME to get get the new path.
# So the quickest and easiest method is to mv the $ISOROOTNAME this avoids having two copies and is simple to understand
# First thoughmake sure we actually build new images
    if [ -e "$ISOROOTNAME/boot/grub/grub-eltorito.img" -o -e "$ISOROOTNAME/boot/grub/grub2-embed_img" ]; then
	$SUDO rm -rf "$ISOROOTNAME/boot/grub/{grub-eltorito,grub-embedded}.img"
    fi

    $SUDO mv -f "$ISOROOTNAME" "$CHROOTNAME"
# Job done just remember to move it back again
# Make the image
    $SUDO chroot "$CHROOTNAME" /usr/bin/grub2-mkimage -d "$GRUB_LIB" -O i386-pc -o "$GRUB_IMG" -p /boot/grub -c /ISO/boot/grub/start_cfg  iso9660 biosdisk test
# Move the ISO director back to the working directory
    $SUDO mv -f "$CHROOTNAME/ISO/" "$WORKDIR"
# Create bootable hard disk image
    $SUDO cat "$CHROOTNAME/$GRUB_LIB/boot.img" "$CHROOTNAME/$GRUB_IMG" > "$ISOROOTNAME/boot/grub/grub2-embed_img"
    if [[ $? != 0 ]]; then
	printf "%s\n -> Failed to create Grub2 El-Torito image. Exiting."
	errorCatch
    fi
# Create bootable cdimage
    $SUDO cat "$CHROOTNAME/$GRUB_LIB/cdboot.img" "$CHROOTNAME/$GRUB_IMG" > "$ISOROOTNAME/boot/grub/grub2-eltorito.img"
    if [[ $? != 0 ]]; then
	printf  "%s\n -> Failed to create Grub2 El-Torito image. Exiting."
	errorCatch
    fi

    XORRISO_OPTIONS1=" -b boot/grub/grub2-eltorito.img -no-emul-boot -boot-info-table --embedded-boot $ISOROOTNAME/boot/grub/grub2-embed_img --protective-msdos-label"

# Copy SuperGrub iso
# disable for now
#    $SUDO cp -rfT $OURDIR/extraconfig/super_grub2_disk_i386_pc_2.00s2.iso "$ISOROOTNAME"/boot/grub/sgb.iso

    printf "%s\n -> End building Grub2 El-Torito image."
    printf "%s\n -> Installing liveinitrd for grub2"

    if [ -e "$CHROOTNAME/boot/vmlinuz-$BOOT_KERNEL_ISO" ] && [ -e "$CHROOTNAME/boot/liveinitrd.img" ]; then
	$SUDO cp -a "$CHROOTNAME/boot/vmlinuz-$BOOT_KERNEL_ISO" "$ISOROOTNAME/boot/vmlinuz0"
	$SUDO cp -a "$CHROOTNAME/boot/liveinitrd.img" "$ISOROOTNAME/boot/liveinitrd.img"
    else
	printf "%s\n -> vmlinuz or liveinitrd does not exists. Exiting."
	errorCatch
    fi

    if [ ! -f "$ISOROOTNAME/boot/liveinitrd.img" ]; then
	printf "%s\n -> Missing /boot/liveinitrd.img. Exiting."
	errorCatch
    else
	$SUDO rm -rf "$CHROOTNAME/boot/liveinitrd.img"
    fi

    XORRISO_OPTIONS="$XORRISO_OPTIONS1 $XORRISO_OPTIONS2"
    $SUDO rm -rf $GRUB_IMG
}


setupISOenv() {

# Set up default timezone
    printf "%s\n -> Setting default timezone %s\n"
    $SUDO ln -sf /usr/share/zoneinfo/Universal "$CHROOTNAME/etc/localtime"

# try harder with systemd-nspawn
# version 215 and never has then --share-system option
#	if (( `rpm -qa systemd --queryformat '%{VERSION} \n'` >= "215" )); then
#	    $SUDO systemd-nspawn --share-system -D "$CHROOTNAME" /usr/bin/timedatectl set-timezone UTC
#	    # set default locale
#	    printf "%sSetting default localization"
#	    $SUDO systemd-nspawn --share-system -D "$CHROOTNAME" /usr/bin/localectl set-locale LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8:en_US:en
#	else
#	    printf "%ssystemd-nspawn does not exists."
#	fi

# Create /etc/minsysreqs
    printf "%s\n -> Creating /etc/minsysreqs"

    if [ "${TYPE,,}" = "minimal" ]; then
	echo "ram = 512" >> "$CHROOTNAME/etc/minsysreqs"
	echo "hdd = 5" >> "$CHROOTNAME/etc/minsysreqs"
    elif [ "$EXTARCH" = "x86_64" ]; then
	echo "ram = 1536" >> "$CHROOTNAME/etc/minsysreqs"
	echo "hdd = 10" >> "$CHROOTNAME/etc/minsysreqs"
    else
	echo "ram = 1024" >> "$CHROOTNAME/etc/minsysreqs"
	echo "hdd = 10" >> "$CHROOTNAME/etc/minsysreqs"
    fi

# Count imagesize and put in in /etc/minsysreqs
    $SUDO echo "imagesize = $(du -a -x -b -P "$CHROOTNAME" | tail -1 | awk '{print $1}')" >> "$CHROOTNAME"/etc/minsysreqs

# Set up displaymanager
    if [ "${TYPE,,}" != "minimal" ] && [ "${DISPLAYMANAGER,,}" != "none" ]; then
	if [ ! -e "$CHROOTNAME"/lib/systemd/system/${DISPLAYMANAGER,,}.service ]; then
	    printf "%s\n -> File ${DISPLAYMANAGER,,}.service does not exist. Exiting."
	    errorCatch
	fi

	$SUDO ln -sf /lib/systemd/system/${DISPLAYMANAGER,,}.service "$CHROOTNAME"/etc/systemd/system/display-manager.service 2> /dev/null || :

# Set reasonable defaults
	if  [ -e "$CHROOTNAME"/etc/sysconfig/desktop ]; then
	    $SUDO rm -rf "$CHROOTNAME"/etc/sysconfig/desktop
	fi

# Create very important desktop file
    cat >"$CHROOTNAME"/etc/sysconfig/desktop <<EOF
DISPLAYMANAGER=$DISPLAYMANAGER
DESKTOP=$TYPE
EOF

    fi

# Copy some extra config files
    $SUDO cp -rfT "$WORKDIR/extraconfig/etc" "$CHROOTNAME"/etc/
    $SUDO cp -rfT "$WORKDIR/extraconfig/usr" "$CHROOTNAME"/usr/

# Set up live user
    live_user=live
    printf "%s\n -> Setting up user ${live_user} %s\n"
    $SUDO chroot "$CHROOTNAME" /usr/sbin/adduser -m -G wheel ${live_user}

# Clear user passwords
    for username in root $live_user; do
# Kill it as it prevents clearing passwords
	if [ -e "$CHROOTNAME"/etc/shadow.lock ]; then
	    $SUDO rm -rf "$CHROOTNAME"/etc/shadow.lock
	fi
	printf "%s\n -> Clearing $username password."
	$SUDO chroot "$CHROOTNAME" /usr/bin/passwd -f -d $username

	if [[ $? != 0 ]]; then
	    printf "%s\n -> Failed to clear $username user password. Exiting."
	    errorCatch
	fi

	$SUDO chroot "$CHROOTNAME" /usr/bin/passwd -f -u $username
    done

    $SUDO chroot "$CHROOTNAME" /bin/mkdir -p /home/${live_user}
    $SUDO chroot "$CHROOTNAME" /bin/cp -rfT /etc/skel /home/${live_user}/
    $SUDO chroot "$CHROOTNAME" /bin/mkdir -p /home/${live_user}/Desktop
    $SUDO cp -rfT "$WORKDIR"/extraconfig/etc/skel "$CHROOTNAME"/home/${live_user}/
    $SUDO chroot "$CHROOTNAME" /bin/mkdir -p /home/${live_user}/.cache
    $SUDO chroot "$CHROOTNAME" /bin/chown -R ${live_user}:${live_user} /home/${live_user}
    $SUDO chroot "$CHROOTNAME" /bin/chown -R ${live_user}:${live_user} /home/${live_user}/Desktop
    $SUDO chroot "$CHROOTNAME" /bin/chown -R ${live_user}:${live_user} /home/${live_user}/.cache
    $SUDO chroot "$CHROOTNAME" /bin/chmod -R 0777 /home/${live_user}/.local
# (tpg) support for AccountsService
    $SUDO chroot "$CHROOTNAME" /bin/mkdir -p /var/lib/AccountsService/users
    $SUDO chroot "$CHROOTNAME" /bin/mkdir -p /var/lib/AccountsService/icons
    $SUDO cp -f "$WORKDIR"/data/account-user "$CHROOTNAME"/var/lib/AccountsService/users/${live_user}
    $SUDO cp -f "$WORKDIR"/data/account-icon "$CHROOTNAME"/var/lib/AccountsService/icons/${live_user}
    $SUDO chroot "$CHROOTNAME" /bin/sed -i -e "s/_NAME_/${live_user}/g" /var/lib/AccountsService/users/${live_user}

# KDE4 related settings
    if [ "${TYPE,,}" = "kde4" ] || [ "${TYPE,,}" = "plasma" ]; then
	$SUDO mkdir -p "$CHROOTNAME"/home/$live_user/.kde4/env
	echo "export KDEVARTMP=/tmp" > "$CHROOTNAME"/home/${live_user}/.kde4/env/00-live.sh
	echo "export KDETMP=/tmp" >> "$CHROOTNAME"/home/${live_user}/.kde4/env/00-live.sh
# disable baloo in live session
	$SUDO mkdir -p "$CHROOTNAME"/home/${live_user}/.kde4/share/config
	cat >"$CHROOTNAME"/home/${live_user}/.kde4/share/config/baloofilerc << EOF
[Basic Settings]
Indexing-Enabled=false
EOF
	$SUDO chroot "$CHROOTNAME" chmod -R 0777 /home/${live_user}/.kde4
	$SUDO chroot "$CHROOTNAME" /bin/chown -R ${live_user}:${live_user} /home/${live_user}/.kde4
    else
	$SUDO rm -rf "$CHROOTNAME"/home/${live_user}/.kde4
    fi

# Enable DM autologin
    if [ "${TYPE,,}" != "minimal" ]; then
	case ${DISPLAYMANAGER,,} in
		"kdm")
		    $SUDO chroot "$CHROOTNAME" sed -i -e 's/.*AutoLoginEnable.*/AutoLoginEnable=True/g' -e 's/.*AutoLoginUser.*/AutoLoginUser=live/g' /usr/share/config/kdm/kdmrc
		    ;;
		"sddm")
		    $SUDO chroot "$CHROOTNAME" sed -i -e "s/^Session=.*/Session=${TYPE,,}.desktop/g" -e 's/^User=.*/User=live/g' /etc/sddm.conf
		    if [ "${TYPE,,}" = "lxqt" ]; then
# (tpg) use maldives theme on LXQt desktop
			$SUDO chroot "$CHROOTNAME" sed -i -e "s/^Current=.*/Current=maldives/g" /etc/sddm.conf
		    fi
		    ;;
		"gdm")
		    $SUDO chroot "$CHROOTNAME" sed -i -e "s/^AutomaticLoginEnable.*/AutomaticLoginEnable=True/g" -e 's/^AutomaticLogin.*/AutomaticLogin=live/g' /etc/X11/gdm/custom.conf
		    ;;
		*)
		    printf "%s -> ${DISPLAYMANAGER,,} is not supported, autologin feature will be not enabled"
	esac
    fi

    $SUDO pushd "$CHROOTNAME"/etc/sysconfig/network-scripts
    for iface in eth0 wlan0; do
	cat > ifcfg-$iface << EOF
DEVICE=$iface
ONBOOT=yes
NM_CONTROLLED=yes
BOOTPROTO=dhcp
EOF
    done
    $SUDO popd

    printf "%s\n -> Starting services setup. %s\n"

# (tpg) enable services based on preset files from systemd and others
    UNIT_DIR="$CHROOTNAME"/lib/systemd/system
    if [ -f $UNIT_DIR-preset/90-default.preset ]; then
	PRESETS=($UNIT_DIR-preset/*.preset)
	for file in "${PRESETS[@]}"; do
	    while read line; do
		if [[ -n "$line" && "$line" != [[:blank:]#]* && "${line,,}" = [[:blank:]enable]* ]]; then
		    SANITIZED="${line#*enable}"
		    for s_file in `find $UNIT_DIR -type f -name $SANITIZED`; do
			DEST=`grep -o 'WantedBy=.*' $s_file  | cut -f2- -d'='`
			if [ -n "$DEST" ] && [ -d "$CHROOTNAME"/etc/systemd/system ] && [ ! -e "$CHROOTNAME"/etc/systemd/system/$DEST.wants/${s_file#$UNIT_DIR/} ] ; then
			    [[ ! -d /etc/systemd/system/$DEST.wants ]] && mkdir -p "$CHROOTNAME"/etc/systemd/system/$DEST.wants
			    printf "%s\n -> Enabling ${s_file#$UNIT_DIR/}"
			    #/bin/systemctl --quiet enable ${s#$UNIT_DIR/};
			    ln -sf /${s_file#$CHROOTNAME/} "$CHROOTNAME"/etc/systemd/system/$DEST.wants/${s_file#$UNIT_DIR/}
			fi
		    done
		fi
	    done < "$file"
	done
    else
	printf "%s\n -> File $UNIT_DIR-preset/90-default.preset does not exist. Installation is broken %s/n"
	errorCatch
    fi


# Enable services on demand
    SERVICES_ENABLE=(getty@tty1.service sshd.socket irqbalance smb nmb winbind)

    for i in "${SERVICES_ENABLE[@]}"; do
	if [[ $i  =~ ^.*socket$|^.*path$|^.*target$|^.*timer$ ]]; then
	    if [ -e "$CHROOTNAME"/lib/systemd/system/$i ]; then
		printf "%s\n -> Enabling $i %s\n"
		ln -sf /lib/systemd/system/$i "$CHROOTNAME"/etc/systemd/system/multi-user.target.wants/$i
	    else
		printf "%s\n -> Special service $i does not exist. Skipping.%s\n"
		fi
	elif [[ ! $i  =~ ^.*socket$|^.*path$|^.*target$|^.*timer$ ]]; then
	    if [ -e "$CHROOTNAME"/lib/systemd/system/$i.service ]; then
		printf "%s\n -> Enabling $i.service %s\n"
		ln -sf /lib/systemd/system/$i.service "$CHROOTNAME"/etc/systemd/system/multi-user.target.wants/$i.service
	    else
		printf "%s\n -> Service $i does not exist. Skipping.%s\n"
	    fi
	else
	    printf "%s\n -> Wrong service match.%s\n"
	fi
    done

# Disable services
    SERVICES_DISABLE=(pptp pppoe ntpd iptables ip6tables shorewall nfs-server mysqld abrtd mariadb mysql mysqld postfix NetworkManager-wait-online chronyd)

    for i in "${SERVICES_DISABLE[@]}"; do
	if [[ $i  =~ ^.*socket$|^.*path$|^.*target$|^.*timer$ ]]; then
	    if [ -e "$CHROOTNAME"/lib/systemd/system/$i ]; then
		printf "%s\n -> Disabling $i %s\n"
		$SUDO rm -rf "$CHROOTNAME"/etc/systemd/system/multi-user.target.wants/$i
	    else
		printf "%s\n -> Special service $i does not exist. Skipping. %s\n"
	    fi
	elif [[ ! $i  =~ ^.*socket$|^.*path$|^.*target$|^.*timer$ ]]; then
	    if [ -e "$CHROOTNAME"/lib/systemd/system/$i.service ]; then
		printf "%s\n -> Disabling $i.service %s\n"
		$SUDO rm -rf "$CHROOTNAME"/etc/systemd/system/multi-user.target.wants/$i.service
	    else
		printf "%s\n -> Service $i does not exist. Skipping. %s\n"
	    fi

	else
	    printf "%s\n -> Wrong service match. %s\n"
	fi
    done

# mask systemd-journald-audit.socket to stop polluting journal with audit spam
    [[ ! -e "$CHROOTNAME"/etc/systemd/system/systemd-journald-audit.socket ]] && ln -sf /dev/null "$CHROOTNAME"/etc/systemd/system/systemd-journald-audit.socket

# ATTENTION getty@.service must be always disabled
    [[ -e "$CHROOTNAME"/etc/systemd/system/getty.target.wants/getty@.service ]] && rm -rf "$CHROOTNAME"/etc/systemd/system/getty.target.wants/getty@.service

# Calamares installer
    if [ -e "$CHROOTNAME"/etc/calamares/modules/displaymanager.conf ]; then

# Enable settings for specific desktop environment
# https://issues.openmandriva.org/show_bug.cgi?id=1424
	sed -i -e "s/.*defaultDesktopEnvironment:.*/defaultDesktopEnvironment:/g" "$CHROOTNAME"/etc/calamares/modules/displaymanager.conf

	if [ "${TYPE,,}" = "plasma" ]; then
	    sed -i -e "s/.*executable:.*/executable: "startkde"/g" "$CHROOTNAME"/etc/calamares/modules/displaymanager.conf
	    sed -i -e "s/.*desktopFile:.*/desktopFile: "plasma"/g" "$CHROOTNAME"/etc/calamares/modules/displaymanager.conf
	fi

	if [ "${TYPE,,}" = "kde4" ]; then
	    sed -i -e "s/.*executable:.*/executable: "startkde"/g" "$CHROOTNAME"/etc/calamares/modules/displaymanager.conf
	    sed -i -e "s/.*desktopFile:.*/desktopFile: "kde-plasma"/g" "$CHROOTNAME"/etc/calamares/modules/displaymanager.conf
	fi

	if [ "${TYPE,,}" = "mate" ]; then
	    sed -i -e "s/.*executable:.*/executable: "mate-session"/g" "$CHROOTNAME"/etc/calamares/modules/displaymanager.conf
	    sed -i -e "s/.*desktopFile:.*/desktopFile: "mate"/g" "$CHROOTNAME"/etc/calamares/modules/displaymanager.conf
	fi

	if [ "${TYPE,,}" = "lxqt" ]; then
	    sed -i -e "s/.*executable:.*/executable: "lxqt-session"/g" "$CHROOTNAME"/etc/calamares/modules/displaymanager.conf
	    sed -i -e "s/.*desktopFile:.*/desktopFile: "lxqt"/g" "$CHROOTNAME"/etc/calamares/modules/displaymanager.conf
	fi

	if [ "${TYPE,,}" = "icewm" ]; then
	    sed -i -e "s/.*desktopFile:.*/desktopFile: "icewm"/g" "$CHROOTNAME"/etc/calamares/modules/displaymanager.conf
	fi

	if [ "${TYPE,,}" = "xfce4" ]; then
	    sed -i -e "s/.*executable:.*/executable: "startxfce4"/g" "$CHROOTNAME"/etc/calamares/modules/displaymanager.conf
	    sed -i -e "s/.*desktopFile:.*/desktopFile: "xfce"/g" "$CHROOTNAME"/etc/calamares/modules/displaymanager.conf
	fi

    fi
#    if [ -e "$CHROOTNAME"/etc/calamares/modules/unpackfs.conf ]; then
#	echo "Updating calamares settings."
	# update patch to squashfs
#	$SUDO sed -i -e "s#source:.*#source: "/media/$LABEL/LiveOS/squashfs.img"#" "$CHROOTNAME"/etc/calamares/modules/unpackfs.conf
#    fi

    #remove rpm db files which may not match the non-chroot environment
    $SUDO chroot "$CHROOTNAME" rm -f /var/lib/rpm/__db.*
# Fix Me This should be a function
# FIX ME There should be a fallback to abf-downloads here or perhaps to a primary mirror.
    if [ -z "$NOCLEAN" ]; then
# add urpmi medias inside chroot
	printf "%s\n -> Removing old urpmi repositories."
	$SUDO urpmi.removemedia -a --urpmi-root "$CHROOTNAME"
    printf "%s\n -> Adding new urpmi repositories."
	if [ "${TREE,,}" = "cooker" ]; then
	    MIRRORLIST="http://downloads.openmandriva.org/mirrors/cooker.$EXTARCH.list"

	    $SUDO urpmi.addmedia --urpmi-root "$CHROOTNAME" --wget --no-md5sum --mirrorlist "$MIRRORLIST" 'Main' 'media/main/release'
	    if [[ $? != 0 ]]; then
		$SUDO urpmi.addmedia --urpmi-root "$CHROOTNAME" --wget --no-md5sum 'Main' http://abf-downloads.openmandriva.org/"${TREE,,}"/repository/"${EXTARCH}"/main/release
	    fi

# Add 32-bit main repository for non i586 build
	    if [ "$EXTARCH" = "x86_64" ]; then
		printf "%s\n -> Adding 32-bit media repository. %s\n"
# Use previous MIRRORLIST declaration but with i586 arch in link name
		MIRRORLIST2="`echo $MIRRORLIST | sed -e "s/x86_64/i586/g"`"
		$SUDO urpmi.addmedia --urpmi-root "$CHROOTNAME" --wget --no-md5sum --mirrorlist "$MIRRORLIST2" 'Main32' 'media/main/release'
		if [[ $? != 0 ]]; then
		$SUDO urpmi.addmedia --urpmi-root "$CHROOTNAME" --wget --no-md5sum 'Main32' http://abf-downloads.openmandriva.org/"${TREE,,}"/repository/i586/main/release
		    if [[ $? != 0 ]]; then
			printf "%s\n -> Adding urpmi 32-bit media FAILED. Exiting"
			errorCatch
		    fi
		fi
	    fi

	    $SUDO urpmi.addmedia --urpmi-root "$CHROOTNAME" --wget --no-md5sum --mirrorlist "$MIRRORLIST" 'Contrib' 'media/contrib/release'
	    if [[ $? != 0 ]]; then
		$SUDO urpmi.addmedia --urpmi-root "$CHROOTNAME" --wget --no-md5sum 'Contrib' http://abf-downloads.openmandriva.org/"${TREE,,}"/repository/"${EXTARCH}"/contrib/release
	    fi
# This one is needed to grab firmwares
	    $SUDO urpmi.addmedia --urpmi-root "$CHROOTNAME" --wget --no-md5sum --mirrorlist "$MIRRORLIST" 'Non-free' 'media/non-free/release'
	    if [[ $? != 0 ]]; then
		$SUDO urpmi.addmedia --urpmi-root "$CHROOTNAME" --wget --no-md5sum 'Non-Free' http://abf-downloads.openmandriva.org/"${TREE,,}"/repository/"${EXTARCH}"/non-free/release
	    fi
	else
	    MIRRORLIST="http://downloads.openmandriva.org/mirrors/openmandriva.${TREE##openmandriva}.$EXTARCH.list"
	    printf "%s -> Using $MIRRORLIST"
	    $SUDO urpmi.addmedia --urpmi-root "$CHROOTNAME" --wget --no-md5sum --distrib --mirrorlist $MIRRORLIST
	    if [[ $? != 0 ]]; then
		printf "%s\n -> Adding urpmi media FAILED. Falling back to use ABF."
		$SUDO urpmi.addmedia --urpmi-root "$CHROOTNAME" --wget --no-md5sum --distrib --mirrorlist http://abf-downloads.openmandriva.org/${TREE##openmandriva}.${EXTARCH}.list
		if [[ $? != 0 ]]; then
		    printf "%s -> Adding urpmi media FAILED. Exiting."
		    errorCatch
		fi
	    fi
	fi

# Update urpmi medias
	printf "%s -> Updating urpmi repositories"
	$SUDO urpmi.update --urpmi-root "$CHROOTNAME" -a -ff --wget --force-key
    fi # noclean

# Get back to real /etc/resolv.conf
    $SUDO rm -f "$CHROOTNAME"/etc/resolv.conf
    if [ "`cat $CHROOTNAME/etc/release | grep -o 2014.0`" == "2014.0" ]; then
	$SUDO ln -sf /run/resolvconf/resolv.conf "$CHROOTNAME"/etc/resolv.conf
    else
	$SUDO ln -sf /run/systemd/resolve/resolv.conf "$CHROOTNAME"/etc/resolv.conf
    fi

# ldetect stuff
    if [ -x "$CHROOTNAME"/usr/sbin/update-ldetect-lst ]; then
	$SUDO chroot "$CHROOTNAME" /usr/sbin/update-ldetect-lst
    fi

# fontconfig cache
    if [ -x "$CHROOTNAME"/usr/bin/fc-cache ]; then
        # set the timestamp on the directories to be a whole second
        # fc-cache looks at the nano second portion which will otherwise be
        # non-zero as we are on ext4, but then it will compare against the stamps
        # on the squashfs live image, squashfs only has second level timestamp resolution
        FCTIME=$(date +%Y%m%d%H%M.%S)
        $SUDO chroot "$CHROOTNAME" find /usr/share/fonts -type d -exec touch -t $FCTIME {} \;
	$SUDO chroot "$CHROOTNAME" fc-cache -rf
	$SUDO chroot "$CHROOTNAME" /bin/mkdir -p /root/.cache/fontconfig/
	$SUDO chroot "$CHROOTNAME" /bin/mkdir -p /${live_user}/.cache/fontconfig/
    fi

# Rebuild man-db
    if [ -x "$CHROOTNAME"/usr/bin/mandb ]; then
    printf "%s\n Please wait...rebuilding man page database %s\n"
    	$SUDO chroot "$CHROOTNAME" /usr/bin/mandb --quiet
    fi

# Rebuild linker cache
    $SUDO chroot "$CHROOTNAME" /sbin/ldconfig

# Clear tmp
    $SUDO rm -rf "$CHROOTNAME"/tmp/*

# Clear urpmi cache
    if [ -f "$CHROOTNAME"/.noclean ]; then
# Move contents of rpm cache away so as not to include in iso
	$SUDO mv "$CHROOTNAME"/var/cache/urpmi/rpms "$WORKDIR"
	$SUDO mkdir -m 755 -p  "$CHROOTNAME"/var/cache/urpmi/rpms
    else
    	$SUDO rm -rf "$CHROOTNAME"/var/cache/urpmi/partial/*
    	$SUDO rm -rf "$CHROOTNAME"/var/cache/urpmi/rpms/*
    fi
# Generate list of installed rpm packages
    $SUDO chroot "$CHROOTNAME" rpm -qa --queryformat="%{NAME}\n" | sort > /var/lib/rpm/installed-by-default

# Remove rpm db files to save some space
    $SUDO rm -rf "$CHROOTNAME"/var/lib/rpm/__db.*
#
 $SUDO echo 'File created by omdv-build-iso. See systemd-update-done.service(8).' \
    | tee "$CHROOTNAME"/etc/.updated >"$CHROOTNAME"/var/.updated

}

createSquash() {
    printf "%s\n -> Starting squashfs image build."
# Before we do anything check if we are a local build
    if [ -n "$IN_ABF" ]; then
# We so make sure that nothing is mounted on the chroots /run/os-prober/dev/ directory.
# If mounts exist mksquashfs will try to build a squashfs.img with contents of all  mounted drives
# It's likely that the img will be written to one of the mounted drives so it's unlikely
# that there will be enough diskspace to complete the operation.
	if [ -f "$ISOCHROOTNAME"/run/os-prober/dev/* ]; then
	    $SUDO umount -l `echo "$ISOCHROOTNAME"/run/os-prober/dev/*`
	    if [ -f "$ISOCHROOTNAME"/run/os-prober/dev/* ]; then
		printf "%s\n -> Cannot unount os-prober mounts aborting."
		errorCatch
	    fi
	fi
    fi

    if [ -f "$ISOROOTNAME"/LiveOS/squashfs.img ]; then
	$SUDO rm -rf "$ISOROOTNAME"/LiveOS/squashfs.img
    fi

    mkdir -p "$ISOROOTNAME"/LiveOS
# Unmout all stuff inside CHROOT to build squashfs image
    umountAll "$CHROOTNAME"

# Here we go with local speed ups
# For development only remove all the compression so the squashfs builds quicker.
# Give it it's own flag QUICKEN.
    if [ -n "$QUICKEN" ]; then
	$SUDO mksquashfs "$CHROOTNAME" "$ISOROOTNAME"/LiveOS/squashfs.img -comp xz -no-progress -noD -noF -noI -no-exports -no-recovery -b 16384
    else
	$SUDO mksquashfs "$CHROOTNAME" "$ISOROOTNAME"/LiveOS/squashfs.img -comp xz -no-progress -no-exports -no-recovery -b 16384
    fi
    if [ ! -f  "$ISOROOTNAME"/LiveOS/squashfs.img ]; then
	printf "%s\n -> Failed to create squashfs. Exiting."
	errorCatch
    fi

}

buildIso() {
# Usage: buildIso filename.iso rootdir
# Builds an ISO file from the files in rootdir

    printf "%s\n -> Starting ISO build. %s\n"

    if [ -n "$IN_ABF" ]; then
	ISOFILE="$WORKDIR/$PRODUCT_ID.$EXTARCH.iso"
    elif [ -z "$OUTPUTDIR" ]; then
	ISOFILE="/home/$WHO/$PRODUCT_ID.$EXTARCH.iso"
    else
	ISOFILE="$OUTPUTDIR/$PRODUCT_ID.$EXTARCH.iso"
    fi

    if [ ! -x /usr/bin/xorriso ]; then
	printf "%s/n -> xorriso does not exists. Exiting."
	errorCatch
    fi

# Before starting to build remove the old iso. xorriso is much slower to create an iso.
# if it is overwriting an earlier copy. Also it's not clear whether this affects the.
# contents or structure of the iso (see --append-partition in the man page)
# Either way building the iso is 30 seconds quicker (for a 1G iso) if the old one is deleted.
    if [ -z "$IN_ABF" ] && [ -n "$ISOFILE" ]; then
	printf "%s -> Removing old iso."
	$SUDO rm -rf "$ISOFILE"
    fi
    printf "%s\n -> Building ISO with options ${XORRISO_OPTIONS} %s\n"

    $SUDO xorriso -as mkisofs -R -r -J -joliet-long -cache-inodes \
	-graft-points -iso-level 3 -full-iso9660-filenames \
	--modification-date=${ISO_DATE} \
	-omit-version-number -disable-deep-relocation \
	${XORRISO_OPTIONS} \
	-publisher "OpenMandriva Association" \
	-preparer "OpenMandriva Association" \
	-volid "$LABEL" -o "$ISOFILE" "$ISOROOTNAME" --sort-weight 0 / --sort-weight 1 /boot

    if [ ! -f "$ISOFILE" ]; then
	printf "%s\n -> Failed build iso image. Exiting"
	errorCatch
    fi

    printf "%s\n -> ISO build completed."
}

postBuild() {

    if [ ! -f $ISOFILE ]; then
	umountAll "$CHROOTNAME"
	errorCatch
    fi

    if [ -n "$IN_ABF" ]; then
# We're running in ABF adjust to its directory structure
# Count checksums
	printf "%s\n -> Generating ISO checksums."
	pushd $WORKDIR
	md5sum $PRODUCT_ID.$EXTARCH.iso > $PRODUCT_ID.$EXTARCH.iso.md5sum
	sha1sum $PRODUCT_ID.$EXTARCH.iso > $PRODUCT_ID.$EXTARCH.iso.sha1sum
	popd

	if [ "$WORKDIR" = "/home/vagrant/iso_builder" ]; then
	    $SUDO mkdir -p /home/vagrant/results /home/vagrant/archives
	    $SUOD mv $WORKDIR/*.iso* /home/vagrant/results/
	else
	    $SUDO mkdir -p $WORKDIR/results $WORKDIR/archives
	    $SUDO mv $WORKDIR/*.iso* $WORKDIR/results/
	fi
    fi

# If .noclean is set move rpms back to the cache directories
    if [ -f "$CHROOTNAME"/.noclean ]; then
	rm -R "$CHROOTNAME"/var/cache/urpmi/rpms
	$SUDO mv -f "$WORKDIR"/rpms "$CHROOTNAME"/var/cache/urpmi/
    fi

# Clean chroot
    umountAll "$CHROOTNAME"
}


# START ISO BUILD
showInfo
updateSystem
if [ "$IN_ABF" == "0" ]; then
localMd5Change
fi
createChroot
createInitrd
createMemDisk
createUEFI
setupGrub2
setupISOenv
createSquash
buildIso
postBuild

#END
