#Categorys
#Setup
#Control
#Logging & Informational
#Save and Restore
# Chroot creation and manipulation



#Package list creation and control
mkOmSpin() {
# Usage: mkOmSpin [main install file path} i.e. [path]/omdv-kde4.lst.
# Returns a variable "$INSTALL_LIST" containing all rpms
# to be installed
    getIncFiles "$FILELISTS" ADDRPMINC
    printf "%s" "$ADDRPMINC" > "$WORKDIR/inclist"
    printf "%s\n" "-> Creating OpenMandriva spin from" "$FILELISTS" " " "   Which includes"
    printf "%s" "$ADDRPMINC" | grep -v "$FILELISTS"  
    createPkgList "$ADDRPMINC" INSTALL_LIST
    mkUpdateChroot "$INSTALL_LIST"
}

mkUserSpin() {
# mkUserSpin [main install file path} i.e. [path]/omdv-kde4.lst
# Sets two variables
# $INSTALL_LIST = All list files to be installed
# $REMOVE_LIST = All list files to be removed
# This function includes all the user adds and removes.
    printf "%s\n" "-> Making a user spin"
    printf "%s\n" "Change Flag = $CHGFLAG"

    getIncFiles "$FILELISTS" ADDRPMINC 
    #"$TYPE"
    printf "%s\n" "$ADDRPMINC" > "$WORKDIR/prime.list"
    getIncFiles "$WORKDIR/iso-pkg-lists-$TREE/my.add" UADDRPMINC
    ALLRPMINC=$(echo "$ADDRPMINC"$'\n'"$UADDRPMINC" | sort -u)
    printf "%s\n" "$ALLRPMINC" > "$WORKDIR/primary.list"
    getIncFiles "$WORKDIR/iso-pkg-lists-$TREE/my.rmv" RMRPMINC
    printf "%s\n" "-> Remove the common include lines for the remove package includes" 
    RMRPMINC=$(comm -1 -3 <(printf '%s\n' "$ALLRPMINC" | sort ) <(printf '%s\n' "$RMRPMINC" | sort))
    printf "%s" "-> Creating $WHO's OpenMandriva spin from $FILELISTS" "  Which includes "
    printf "%s\n" "$ALLRPMINC" | grep -v "$FILELISTS"
    # Create the package lists
    createPkgList "$ALLRPMINC" INSTALL_LIST
    createPkgList "$RMRPMINC" REMOVE_LIST
    mkUpdateChroot "$INSTALL_LIST" "$REMOVE_LIST"
}

updateUserSpin() {
# updateUserSpin [main install file path] i.e. path/omdv-kde4.lst
# Sets two variables
# INSTALL_LIST = All list files to be installed
# REMOVE_LIST = All list files to be removed
# This function only updates using the user my.add and my.rmv files.
# It is used to add user updates after the main chroot
# has been created with mkUserSpin.
    printf "%s\n" "-> Updating user spin"
    getIncFiles "$WORKDIR/iso-pkg-lists-$TREE/my.add" UADDRPMINC
# re-assign just for consistancy
    ALLRPMINC="$UADDRPMINC"
    getIncFiles "$WORKDIR/iso-pkg-lists-$TREE/my.rmv" RMRPMINC
# "Remove any duplicate includes"
RMRPMINC=$(comm -1 -3 <(printf '%s\n' "$ALLRPMINC" | sort ) <(printf '%s\n' "$RMRPMINC" | sort))
    createPkgList "$ALLRPMINC" INSTALL_LIST
    createPkgList "$RMRPMINC" REMOVE_LIST
	printf "%s\n" " " "-> This is the user list"
	printf "%s\n" "$ALLRPMINC"
	printf "%s\n" " " "-> This is the remove list"
	printf "%s\n" "$RMRPMINC" " "
	if [ -n "$DEVMODE" ]; then
	$SUDO printf '%s\n' "$ALLRPMINC" >"$WORKDIR/add_incfile.list" " "
	$SUDO printf '%s\n' "$RMRPMINC" >"$WORKDIR/remove_incfile.list" " "
    fi
#    Remove any packages that occur in both lists
#    REMOVE_LIST=`comm -1 -3 --nocheck-order <(printf '%s\n' "$INSTALL_LIST" | sort) <(printf '%s\n' "$PRE_REMOVE_LIST" | sort)`
printf "%s\n" "$REMOVE_LIST"
    if [ -n "$DEVMODE" ]; then
	$SUDO printf '%s\n' "$INSTALL_LIST" >"$WORKDIR/user_update_add_rpmlist" " "
	$SUDO printf '%s\n' "$REMOVE_LIST" >"$WORKDIR/user_update_rm_rpmlist" " "
    fi
    mkUpdateChroot  "$INSTALL_LIST" "$REMOVE_LIST"
        printf "%s\n" "$INSTALL_LIST" "$REMOVE_LIST"
}


getPkgList() {
    # update iso-pkg-lists from GitHub if required
    # we need to do this for ABF to ensure any edits have been included
    # Do we need to do this if people are using the tool locally?
    if [[ ( "$IN_ABF" == "1" && -n "$DEBUG" ) || "$IN_ABF" == "0" ]]; then
        if [ ! -d "$WORKDIR/sessrec/base_lists" ]; then
            mkdir -p "$WORKDIR/sessrec/base_lists/"
        fi

        if [ ! -d "$WORKDIR/iso-pkg-lists-${TREE,,}" ]; then
            printf "%s\n" "-> Could not find $WORKDIR/iso-pkg-lists-${TREE,,}. Downloading from GitHub."
            # download iso packages lists from https://github.com
            # GitHub doesn't support git archive so we have to jump through hoops and get more file than we need
            if [ -n "ISO_VER" ]; then
                GIT_BRNCH="$ISO_VER"
            elif [ ${TREE,,} == "cooker" ]; then
                GIT_BRNCH=master
            else 
                GIT_BRNCH=${TREE,,}
                # ISO_VER defaults to user entry
            fi
        EXCLUDE_LIST=".abf.yml ChangeLog Developer_Info Makefile README TODO omdv-build-iso.sh omdv-build-iso.spec docs/* tools/*"
        wget -qO- https://github.com/OpenMandrivaAssociation/omdv-build-iso/archive/${GIT_BRNCH}.zip | bsdtar  --cd ${WORKDIR}  --strip-components 1 -xvf -
        cd "$WORKDIR" || exit;
        $SUDO rm -rf ${EXCLUDE_LIST}
        cp -r "$WORKDIR"/iso-pkg-lists* "$WORKDIR/sessrec/base_lists/"	
        fi
        if [ ! -e "$FILELISTS" ]; then
        printf "%s\n" "-> $FILELISTS does not exist. Exiting"
        errorCatch
        fi
    fi
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
# This function is not used when the script is run on ABF.

	if [[ "$IN_ABF" == "1" && -z "$DEBUG" ]]; then
        return 0
    fi
   	local __difflist
    BASE_LIST=$WORKDIR/sessrec/base_lists/iso-pkg-lists-${TREE}
    WORKING_LIST=$WORKDIR/iso-pkg-lists-${TREE}
       	
    if [ -f "$WORKDIR/.new" ]; then
        printf "%s\n" "-> Making reference file sums"
        REF_FILESUMS=$($SUDO find ${BASE_LIST}/my.add ${BASE_LIST}/my.rmv ${BASE_LIST}/*.lst -type f -exec md5sum {} \; | tee "$WORKDIR/sessrec/ref_filesums")
        printf "%s\n" "-> Making directory reference sum"
        REF_CHGSENSE=$(printf "%s" "$REF_FILESUMS" | colrm 33 | md5sum | tee "$WORKDIR/sessrec/ref_chgsense")
        printf "%s\n" "$BUILD_ID" > "$WORKDIR/sessrec/.build_id"
        printf "%s\n" "-> Recording build identifier"
        $SUDO rm -rf "$WORKDIR/.new"
    elif [ -n "$NOCLEAN" ]; then
        # Regenerate the references for the next run
        REF_FILESUMS=$($SUDO find ${BASE_LIST}/my.add ${BASE_LIST}/my.rmv ${BASE_LIST}/*.lst -type f -exec md5sum {} \; | tee "$WORKDIR/sessrec/ref_filesums")
        printf "%s\n" "-> Making reference file sums"
        REF_CHGSENSE=$(printf "%s" "$REF_FILESUMS" | colrm 33 | md5sum | tee "$WORKDIR/sessrec/ref_chgsense")
        printf "%s\n" "-> Making directory reference sum"
    fi
        if [ -n "$DEBUG" ]; then
            printf "%s\n" "$REF_CHGSENSE"
            printf "%s\n" "$REF_FILESUMS"
        fi
    
    REF_CHGSENSE=$(cat "$WORKDIR/sessrec/ref_chgsense")
    REF_FILESUMS=$(cat "$WORKDIR/sessrec/ref_filesums")
    printf "%s\n" "-> References loaded"
    
	# Generate the references for this run
	# Need to be careful here; there may be backup files so get the exact files
    # Order is important (sort?)
        NEW_FILESUMS=$($SUDO find ${WORKING_LIST}/my.add ${WORKING_LIST}/my.rmv ${WORKING_LIST}/*.lst -type f -exec md5sum {} \; | tee $WORKDIR/sessrec/new_filesums)
    NEW_CHGSENSE=$(printf "%s" "$NEW_FILESUMS" | colrm 33 | md5sum | tee "$WORKDIR/sessrec/new_chgsense")
    printf "%s\n" "-> New references created" 
    if [ -n "$DEBUG" ]; then
        printf "%s\n" "Directory Reference checksum" "$REF_CHGSENSE"
        printf "%s\n" "Reference Filesums" "$REF_FILESUMS" 
        printf "%s\n" "New Directory Reference checksum" "$NEW_CHGSENSE" 
        printf "%s\n" "New Filesums"  "$NEW_FILESUMS" 
    fi
        if [ "$NEW_CHGSENSE" == "$REF_CHGSENSE" ]; then
        CHGFLAG=0
        else
        $SUDO printf "%s\n" "$NEW_CHGSENSE" >"$WORKDIR/sessrec/ref_chgsense"
        CHGFLAG=1
        fi
	if [ "$CHGFLAG" == "1" ]; then
	    printf "%s\n" "-> Your build files have changed"
	# Create a list of changed files by diffing checksums
    # In these circumstances awk does a better job than diff
    # This looks complicated but all it does is to put the two fields in each file into independent arrays,
    # compares the first field from each file and if they are not equal then print the second field (filename) from each file.
        DIFFILES=$(awk 'NR==FNR{c[NR]=$2; d[NR]=$1;next}; {e[FNR]=$1; f[FNR]=$2}; {if(e[FNR] == d[FNR]){} else{print c[FNR],"   "f[FNR]}}' "$WORKDIR/sessrec/ref_filesums" "$WORKDIR/sessrec/new_filesums") 
        MODFILES="${DIFFILES}"
        if [ -n "$DEBUG" ]; then 
            printf "%s\n" "$MODFILES"
        fi
        #$SUDO mv "$WORKDIR/sessrec/tmp_new_filesums" "$WORKDIR/sessrec/new_filesums"
        USERMOD=$(printf '%s' "$DIFFILES" | grep 'my.add\|my.rmv')
        if [ -z "$USERMOD" ]; then
            printf "%s\n" "-> No Changes"
            return 0
        fi
    # Here just the standard files are diffed ommitting my.add and my.remove
    # Intended for developers creating new compilations. Only active if DEVMODE is set in the env.
    # This list is intended for Developers
    DEVMOD=$(printf '%s' "$DIFFILES" | grep -v 'my.add\|my.rmv')
    # Create a diff for the users reference
        diffPkgLists "$USERMOD"
    elif [[ -n "$DEBUG"  && ( -n "$DEVMOD" || -n "$DEVMODE" ) ]]; then #DEVMOD not empty so run a full update.
    # Create a developer diff ommitting my.add and my.rmv
    diffPkgLists "$DEVMOD"
    fi
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

    local __difflist="$1"
	local __newdiffname
	local dodiff="/usr/bin/diff -Naur"
	
	# Here a combined diff is created
	while read -r DIFF ; do
	ALL+=$(eval  "$dodiff" "$DIFF")$'\n'
	done < <(printf '%s\n' "$__difflist")
	
	if [ -n "$__difflist" ]; then
	# BUILD_ID and SEQNUM are used to label diffs
        if [ -f "$WORKDIR/sessrec/.build_id" ]; then
                SESSNO=$(cat "$WORKDIR"/sessrec/.build_id)
        else
            SESSNO=${BUILD_ID}
        fi
        if [ -f "$WORKDIR/sessrec/.seqnum" ]; then
            SEQNUM=$(cat "$WORKDIR"/sessrec/.seqnum)
        else
            SEQNUM=1
            $SUDO echo "$SEQNUM" >"$WORKDIR/sessrec/.seqnum"
        fi
        __newdiffname="${SESSNO}_${SEQNUM}.diff"
        $SUDO printf "%s" "$ALL" >"$WORKDIR"/sessrec/"$__newdiffname"
        SEQNUM=$((SEQNUM+1))
        $SUDO printf "$SEQNUM" >"$WORKDIR/sessrec/.seqnum"
    fi
}

getIncFiles() {
# Usage: getIncFiles [filename] xyz.* $"[name of variable to return] 
# Returns a sorted list of include files
# Function: Gets all the include lines for the specified package file
# The full path to the package list must be supplied

# Define a some local variables
    local __infile=$1   # The main build file
    local __incflist=$2 # Carries returned variable
getEntrys() {
    # Recursively fetch included files
    while read -r r; do 
     echo "$r"
	[ -z "$r" ] && continue 
	# $'\n' nothing else works just don't go there.
	__addrpminc+=$'\n'"$WORKDIR/iso-pkg-lists-$TREE/$r" 
	getEntrys "$WORKDIR/iso-pkg-lists-$TREE/$r" 
# Avoid sub-shells make sure commented out includes are removed.
    done < <(cat "$1" | grep  '^[A-Za-z0-9 \t]*%include' | sed '/ #/d' | awk -F\./// '{print $2}' | sed '/^\s$/d' | sed '/^$/d') > /dev/null 2>&1
}
     getEntrys "$1"
   # Add the primary file to the list
   	__addrpminc+=$'\n'"$__infile"
    # Sort and remove dupes.
   	__addrpminc=$(printf "%s" "$__addrpminc" | sort -u | uniq -u) 
   	# Export
    eval $__incflist="'$__addrpminc'"
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
# Define a local variable to hold user VAR
    local __pkglist=$2 # Carries returned variable name
# other locals not needed outside routine
    local __pkgs # The list of packages
    local __pkglst # The current package list
    while read -r __pkglst; do
	__pkgs+=$'\n'$(cat "$__pkglst" 2> /dev/null)
    done < <(printf '%s\n' "$1") 
# sanitise regex compliments of TPG
    __pkgs=$(printf '%s\n' "$__pkgs" | grep -v '%include' | sed -e 's,        , ,g;s,  *, ,g;s,^ ,,;s, $,,;s,#.*,,' | sed -n '/^$/!p' | sed 's/ $//')
    #The above was getting comments that occured after the package name i.e. vim-minimal #mini-iso9660. but was leaving a trailing space which confused parallels and it failed the install

    eval $__pkglist="'$__pkgs'"
    if [ -n "$DEBUG" ]; then
	printf  "%s\n" "-> This is the $2 package list"
	printf "%s\n" "$__pkgs"
	$SUDO printf "%s" "$__pkgs" >"$WORKDIR/$2.list"
    fi

    shopt -u lastpipe
    set -m
}

#Help
usage_help() {

    if [[ -z "$EXTARCH" && -z "$TREE" && -z "$VERSION" && -z "$RELEASE_ID" && -z "$TYPE" && -z "$DISPLAYMANAGER" ]]; then
	printf "%s\n" "Please run script with arguments"
	printf "%s\n" "usage $0 [options]"
        printf "%s\n" "general options:"
        printf "%s\n" "--arch= Architecture of packages: i586, x86_64"
        printf "%s\n" "--tree= Branch of software repository: cooker, 3.0, openmandriva2014.0"
        printf "%s\n" "--version= Version for software repository: 2015.0, 2014.1, 2014.0"
        printf "%s\n" "--release_id= Release identifer: alpha, beta, rc, final"
        printf "%s\n" "--type= User environment type on ISO: Plasma, KDE4, MATE, LXQt, IceWM, hawaii, xfce4, weston, minimal"
        printf "%s\n" "--displaymanager= Display Manager used in desktop environemt: KDM, GDM, LightDM, sddm, xdm, none"
        printf "%s\n" "--workdir= Set directory where ISO will be build"
        printf "%s\n" "--outputdir= Set destination directory to where put final ISO file"
        printf "%s\n" "--debug Enable debug output"
        printf "%s\n" "--urpmi-debug Enable urpmi debugging output"
        printf "%s\n" "--noclean Do not clean build chroot and keep cached rpms. Updates chroot with new packages"
        printf "%s\n" "--rebuild Clean build chroot and rebuild from cached rpm's"
        printf "%s\n" "--boot-kernel-type Type of kernel to use for syslinux (eg nrj-desktop), if different from standard kernel"
        printf "%s\n" "--devmode Enables some developer aids see the README"
        printf "%s\n" "--quicken Set up mksqaushfs to use no compression for faster iso builds. Intended mainly for testing"
        printf "%s\n" "--keep Use this if you want to be sure to preserve the diffs of your session when building a new iso session"
        printf "%s\n" "--testrepo Includes the main testing repo in the iso build"
        printf "%s\n" "--auto-update Update the iso filesystem to the latest package versions. Saves rebuilding"
        printf "%s\n" "--enable-skip-list Links a user created skip.list into the /etc/uprmi/ directory. Can be used in conjunction with --auto-update"
        printf "%s\n" " "
        printf "%s\n" "For example:"
        printf "%s\n" "omdv-build-iso.sh --arch=x86_64 --tree=cooker --version=2015.0 --release_id=alpha --type=lxqt --displaymanager=sddm"
        printf "%s\n" "Note that when --type is set to user the user may select their own ISO name during the execution of the script"
        printf "%s\n" "For detailed usage instructions consult the files in /usr/share/omdv-build-iso/docs/"
        printf "%s\n" "Exiting."
	exit 1
    else
	return 0
    fi
}





#Option Checking and setupup
allowedOptions() {
if [ "$ABF" == "1" ]; then
    IN_ABF=1
    printf "%s\n" "-> We are in ABF (https://abf.openmandriva.org) environment"
    if [ -n "$NOCLEAN" ] && [ -n  "$DEBUG" ]; then
    printf "%s\n" "-> using --noclean inside ABF DEBUG instance"
    elif [ -n "$NOCLEAN" ]; then
	printf "%s\n" "-> You cannot use --noclean inside ABF (https://abf.openmandriva.org)"
	exit 1
    fi
# Allow the use of --workdir if in debug mode
    if  [ "$WORKDIR" != "/home/omv/build_iso" ] && [ -n  "$DEBUG" ]; then
    printf "%s\n" "-> using --workdir inside ABF DEBUG instance"
    elif  [ -n  "$WORKDIR" ]; then
	printf "%s\n" "-> You cannot use --workdir inside ABF (https://abf.openmandriva.org)"
	exit 1
    fi
    if [ -n "$KEEP" ]; then
	printf "%s\n" "-> You cannot use --keep inside ABF (https://abf.openmandriva.org)"
	exit 1
    fi
    if	[ -n "$NOCLEAN" ] && [ -n "$REBUILD" ]; then
	printf "%s\n" "-> You cannot use --noclean and --rebuild together"
	exit 1
    fi
    if	[ -n "$REBUILD" ]; then
	printf "%s\n" "-> You cannot use --rebuild inside ABF (https://abf.openmandriva.org)"
	exit 1
    fi
else
    IN_ABF=0
fi
printf  "%s\n" "In abf = $IN_ABF"
}

userISONme() {
printf "%s\n" "Please give a name to your iso e.g Enlight"
read -r in1
echo "$in1"
if [ -n "$in1" ]; then
printf "%s\n" "The isoname will be $in1" "Is this correct y or n ?"
cfrmISONme 
fi
printf "%s\n" "Your iso's name will be $UISONAME"
}

cfrmISONme() {    
read -r in2
echo $in2
if [[ $in2 == "yes" || $in2 == "y" ]]; then
UISONAME="$in1"
return 0
fi
if [[ $in2 == "no" || $in2 == "n" ]]; then
userISONme
fi
}


#Setup
setWorkdir() {
# Set the $WORKDIR
# If ABF=1 then $WORKDIR codes to /bin on a local system so if you try and test with ABF=1 /bin is rm -rf ed.
# To avoid this and to allow testing use the --debug flag to indicate that the default ABF $WORKDIR path should not be used
# To ensure that the WORKDIR does not get set to /usr/bin if the script is started we check the WORKDIR path used by abf and 
# To allow testing the default ABF WORKDIR is set to a different path if the DEBUG option is set and the user is non-root.

if [[ "$IN_ABF" == "1"  &&  ! -d '/home/omv/docker-iso-worker'  &&  -z "$DEBUG" ]]; then
printf "%s\n" "-> DO NOT RUN THIS SCRIPT WITH ABF=1 ON A LOCAL SYSTEM WITHOUT SETTING THE DEBUG OPTION"
exit 1
elif [[  "$IN_ABF" == "1" && -n "$DEBUG" && "$WHO" != "omv" ]]; then
printf "%s\n" "-> Debugging ABF build locally"
#Here we are with ABF=1 and in DEBUG mode,  running on a local system.
# Avoid setting the usual ABF WORKDIR
# if WORKDIR is not defined then set a default'
    if [ -z "$WORKDIR" ]; then
    echo "$SUDOVAR"
    WORKDIR="$UHOME/omdv-build-chroot-$EXTARCH"
    printf "%s\n" "-> The build directory is $WORKDIR"
    fi
fi
if [[ "$IN_ABF" == "1" && -d '/home/omv/docker-iso-worker' ]]; then
    # We really are in ABF
    WORKDIR=$(realpath "$(dirname "$0")")
fi
if [ "$IN_ABF" == "0" ]; then
    if [ -z "$WORKDIR" ]; then
    WORKDIR="$UHOME/omdv-build-chroot-$EXTARCH"
    fi
fi
printf "%s\n" "-> The work directory is $WORKDIR"
# Define these earlier so that files can be moved easily for the various save options
# this is where rpms are installed
CHROOTNAME="$WORKDIR/BASE"
# this is where ISO files are created
ISOROOTNAME="$WORKDIR/ISO"
}

mkISOLabel() {
# Create the ISO and grub2 directorys
$SUDO mkdir -m 0755 -p "$ISOROOTNAME"/EFI/BOOT
$SUDO mkdir -m 0755 -p "$ISOROOTNAME"/boot/grub2

# UUID Generation. xorriso needs a string of 16 asci digits.
# grub2 needs dashes to separate the fields..
GRUB_UUID="$(date -u +%Y-%m-%d-%H-%M-%S-00)"
ISO_DATE="$(printf "%s" "$GRUB_UUID" | sed -e s/-//g)"
# in case when i386 is passed, fall back to i586
[ "$EXTARCH" = "i386" ] && EXTARCH=i586

if [ "${RELEASE_ID,,}" == "final" ]; then
    PRODUCT_ID="OpenMandrivaLx.$VERSION"
elif [ "${RELEASE_ID,,}" == "alpha" ]; then
    RELEASE_ID="$RELEASE_ID.$(date +%Y%m%d)"
fi
# Check if user build if true fixup name logic
if [ "$TYPE" = "my.add" ]; then
PRODUCT_ID="OpenMandrivaLx.$VERSION-$RELEASE_ID-$UISONAME"
else
    PRODUCT_ID="OpenMandrivaLx.$VERSION-$RELEASE_ID-$TYPE"
fi
printf "%s" "$PRODUCT_ID"

LABEL="$PRODUCT_ID.$EXTARCH"
[ `echo "$LABEL" | wc -m` -gt 32 ] && LABEL="OpenMandrivaLx_$VERSION"
[ `echo "$LABEL" | wc -m` -gt 32 ] && LABEL="$(echo "$LABEL" |cut -b1-32)"
}

# Chroot creation and manipulation
createChroot() {
# Usage: createChroot packages.lst /target/dir
# Creates a chroot environment with all packages in the packages.lst
# file and their dependencies in /target/dir

if [ "$CHGFLAG" != "1" ]; then
    if [[ ( -f "$CHROOTNAME"/.noclean && ! -d "$CHROOTNAME/lib/modules") || -n "$REBUILD" ]]; then 
        printf "%s\n" "-> Creating chroot $CHROOTNAME" 
    else 
        printf "%s\n" "-> Updating existing chroot $CHROOTNAME"
    fi
# Make sure /proc, /sys and friends are mounted so %post scripts can use them
# Note that below mkdir -p creates $WORKDIR/BASE 
    $SUDO mkdir -p "$CHROOTNAME/proc" "$CHROOTNAME/sys"  "$CHROOTNAME/dev/pts"

if [ -n "$REBUILD" ]; then
    ANYRPMS=$(find "$CHROOTNAME/var/cache/urpmi/rpms/" -name "basesystem-minimal*.rpm"  -printf -quit)
    if [ -n "$ANYRPMS" ]; then
        printf "%s\n" "-> Rebuilding." 
        else
        printf "%s\n" "-> You must run with --noclean before you use --rebuild"
        errorCatch
    fi
fi

# If chroot exists and if we have --noclean then the repo files are not needed with exception of the
# first time run with --noclean when they must be installed. If --rebuild is called they will have been
# deleted so reinstall them. 
    REPOPATH="http://abf-downloads.openmandriva.org/${TREE,,}/repository/$EXTARCH/"
    printf "%s" "$REPOPATH"
# If the kernel hasn't been installed then it's a new chroot or a rebuild
    if [[ ! -d "$CHROOTNAME"/lib/modules || -n "$REBUILD" ]]; then
	printf "%s\n" "-> Adding urpmi repository $REPOPATH into $CHROOTNAME" " "
        if [ "${TREE,,}" != "cooker" ]; then
        $SUDO urpmi.addmedia --wget --urpmi-root "$CHROOTNAME" "Main" $REPOPATH/main/release
        # This one is needed to grab firmwares
        $SUDO urpmi.addmedia --wget --urpmi-root "$CHROOTNAME" "Non-free" $REPOPATH/non-free
        # and this one for the users local stuff 
        $SUDO urpmi.addmedia --urpmi-root "$CHROOTNAME" "local" file://home/colin/Development/fixuprepo
        elif [ "$FREE" = "0" ]; then
        $SUDO urpmi.addmedia --wget --urpmi-root "$CHROOTNAME" --distrib $REPOPATH
            if [ -n "$TESTREPO" ]; then
            $SUDO urpmi.addmedia --wget --urpmi-root "$CHROOTNAME" "MainTesting" $REPOPATH/main/testing
            fi
        else
        $SUDO urpmi.addmedia --wget --urpmi-root "$CHROOTNAME" "Main" $REPOPATH/main/release
        $SUDO urpmi.addmedia --wget --urpmi-root "$CHROOTNAME" "Contrib" $REPOPATH/contrib/release
        # This one is needed to grab firmwares
        $SUDO urpmi.addmedia --wget --urpmi-root "$CHROOTNAME" "Non-free" $REPOPATH/non-free/release
        fi
        # and this one for the users local stuff 
        if [ -n "$LOCLREP" ]; then
            $SUDO urpmi.addmedia --urpmi-root "$CHROOTNAME" "local" file://"$LCLREP"
        fi
    else # It's and existing chroot so update it.
    printf "%s -> Updating urpmi repositories in $CHROOTNAME"
    $SUDO urpmi.update -a -c -ff --wget --urpmi-root "$CHROOTNAME"
	fi


    $SUDO mount --bind /proc "$CHROOTNAME"/proc
    $SUDO mount --bind /sys "$CHROOTNAME"/sys
    $SUDO mount --bind /dev "$CHROOTNAME"/dev
    $SUDO mount --bind /dev/pts "$CHROOTNAME"/dev/pts

# Start rpm packages installation 
# CHGFLAG=1 Indicates a global change in the iso lists

# If IN_ABF=1 is set then build a standard iso
# No other optiona are available

# If IN_ABF=1 and DEBUG are set then we are in ABF mode locally. 
# In this mode the NOCLEAN flag is allowed. 

# If the NOCLEAN flag set this will first build a standard iso, once built subsequent runs 
# with NOCLEAN set will update the chroot with any changed file entries.

# If IN_ABF=0 and the NOCLEAN flags are set this will build an iso using the standard files 
# plus the contents of the two user files my.add and my.rmv. 
# Once built subsequent runs with NOCLEAN flag set will update the chroot with 
# any changed entries in the user files only. 

# if REBUILD is set then the chroot will be rebuilt using the standard and user file lists. 
# This uses the preserved rpm cache to speed up the rebuild. 
# Files that were added to the user files will be downloaded.

    # Build from scratch
    if [[ -z "$NOCLEAN" && -z "$REBUILD" ]]; then
        printf "%s\n" "Creating chroot" 
        mkOmSpin
     # Build the initial noclean chroot this is user mode only and will include the two user files my.add and my.rmv
    elif [[ -n "$NOCLEAN" && ! -e "$CHROOTNAME"/.noclean && "$IN_ABF" == "0" ]]; then 
        printf "%s\n" "Creating an user chroot"
        mkUserSpin
     # Build the initial noclean chroot in ABF test mode and will use just the base lists   
    elif [[ -n "$NOCLEAN" && ! -e "$CHROOTNAME"/.noclean && "$IN_ABF" == "1" && -n "$DEBUG" ]]; then
#    elif [[ -n "$NOCLEAN" && ! -e "$CHROOTNAME"/.noclean && "$IN_ABF" == "1" ]]; then    
        printf "%s\n" "Creating chroot in ABF developer mode"
        mkOmSpin
    # Update a noclean chroot with the contents of the user files my.add and my.rmv 
    elif [[ -n "$AUTO_UPDATE" && -n "$NOCLEAN" && -e "$CHROOTNAME"/.noclean && "$IN_ABF" == "0" ]]; then
        #$SUDO chroot "$CHROOTNAME"
       $SUDO /usr/sbin/urpmi --auto-update --force --urpmi-root "$CHROOTNAME"
    elif 
    [[ -n "$NOCLEAN" && -e "$CHROOTNAME"/.noclean && "$IN_ABF" == "0" ]]; then
        updateUserSpin
        printf "%s\n" "-> Updating user spin"
    # Rebuild the users chroot from cached rpms
    elif [ -n "$REBUILD" ]; then
        printf  "%s\n" "-> Rebuilding." 
        mkUserSpin "$FILELISTS"
    fi
 
	$SUDO touch "$CHROOTNAME/.noclean"
 

    if [[ $? != 0 ]] && [ ${TREE,,} != "cooker" ]; then
	printf "%s\n" "-> Can not install packages from $FILELISTS"
	errorCatch
    fi

# Check CHROOT
    if [ ! -d  "$CHROOTNAME"/lib/modules ]; then
	printf "%s\n" "-> Broken chroot installation." "Exiting" 
	errorCatch
    fi
# Export installed and boot kernel
    pushd "$CHROOTNAME"/lib/modules > /dev/null 2>&1
    BOOT_KERNEL_ISO="$(ls -d --sort=time [0-9]*-${BOOT_KERNEL_TYPE}* | head -n1 | sed -e 's,/$,,')"
    export BOOT_KERNEL_ISO
    if [ -n "$BOOT_KERNEL_TYPE" ]; then
	$SUDO echo "$BOOT_KERNEL_TYPE" > "$CHROOTNAME/boot_kernel"
	KERNEL_ISO=$(ls -d --sort=time [0-9]* | grep -v "$BOOT_KERNEL_TYPE" | head -n1 | sed -e 's,/$,,')
    else
	KERNEL_ISO=$(ls -d --sort=time [0-9]* |head -n1 | sed -e 's,/$,,')
    fi
    export KERNEL_ISO
    popd > /dev/null 2>&1
# remove rpm db files which may not match the target chroot environment
    $SUDO chroot "$CHROOTNAME" rm -f /var/lib/rpm/__db.*
}

#Save and Restore
SaveDaTa() {
printf %s\n "Saving config data"
if [ -n "$KEEP" ]; then
mv "$WORKDIR/iso-pkg-lists-${TREE,,}" "$UHOME/iso-pkg-lists-${TREE,,}"
mv "$WORKDIR/sessrec" "$UHOME/sessrec"
fi
mv "$WORKDIR/dracut" "$UHOME/dracut"
mv "$WORKDIR/grub2" "$UHOME/grub2"
mv "$WORKDIR/boot" "$UHOME/boot"
if [ -n "$REBUILD" ]; then
printf %s\n "-> Saving rpms for rebuild"
$SUDO mv "$CHROOTNAME/var/cache/urpmi/rpms" "$UHOME/RPMS"
fi
}

RestoreDaTa() {
printf %s\n  "->    Cleaning WORKDIR"
# Re-creates the WORKDIR and populates it with saved data
# In the case of a rebuild the $CHRROTNAME dir is recreated and the saved rpm cache is restored to it..
$SUDO rm -rf "$WORKDIR"
$SUDO mkdir -p "$WORKDIR"
if [ -n "$KEEP" ]; then
printf %s\n "-> Restoring package lists and the session records"
mv "$UHOME/iso-pkg-lists-${TREE,,}" "$WORKDIR/iso-pkg-lists-${TREE,,}"
mv "$UHOME/sessrec" "$WORKDIR/sessrec"
fi
mv "$UHOME/dracut" "$WORKDIR/dracut"
mv "$UHOME/grub2" "$WORKDIR/grub2"
mv "$UHOME/boot" "$WORKDIR/boot"
if [ -n "$REBUILD" ]; then
printf %s\n "-> Restoring rpms for new build"
#Remake needed directories
$SUDO mkdir -p "$CHROOTNAME/proc" "$CHROOTNAME/sys" "$CHROOTNAME/dev/pts"
$SUDO mkdir -p "$CHROOTNAME/var/lib/rpm" #For the rpmdb
$SUDO mkdir -p "$CHROOTNAME/var/cache/urpmi"
$SUDO mv "$UHOME/RPMS" "$CHROOTNAME/var/cache/urpmi/rpms"
fi
$SUDO touch "$WORKDIR/.new"
}

RemkWorkDir() {
echo "Remake dirs"
$SUDO rm -rf "$WORKDIR"
$SUDO mkdir -p "$WORKDIR"
if [ "$IN_ABF" == "0" ]; then
$SUDO touch "$WORKDIR/.new"
fi
}

#Logging & Informational

showInfo() {

	echo $'###\n'
	printf "%s\n" "Building ISO with arguments:"
	printf "%s\n" "Distribution is $DIST"
	printf "%s\n" "Architecture is $EXTARCH"
	printf "%s\n" "Tree is $TREE"
	printf "%s\n" "Version is $VERSION"
	printf "%s\n" "Release ID is $RELEASE_ID"
	if [ "${TYPE,,}" == "my.add" ]; then
        printf "%s\n" "TYPE is user"
    else    
	printf "%s\n" "Type is $TYPE"
	fi
	if [ "${TYPE,,}" == "minimal" ]; then
	    printf "%s\n" "-> No display manager for minimal ISO."
    elif [ "${TYPE,,}" == "my.add" ] && [ -z "$DISPLAYMANAGER" ]; then
        printf "%s\n" "-> No display manager for user ISO."
	else
	    printf "%s\n" "Display Manager is $DISPLAYMANAGER"
	fi
	printf "%s\n" "ISO label is $LABEL"
	printf "%s\n" "Build ID is $BUILD_ID"
	printf "%s\n" "Working directory is $WORKDIR"
	if  [ -n "$REBUILD" ]; then
	    printf "%s\n" "-> All rpms will be re-installed"
	elif [ -n "$NOCLEAN" ]; then
	    printf "%s\n" "-> Installed rpms will be updated"
	fi
	if [ -n "$DEBUG" ]; then
	    printf "%s\n" "-> Debugging enabled"
	fi
	if [ -n "$QUICKEN" ]; then
	    printf "%s\n" "-> Squashfs compression disabled"
	fi
	if [ -n "$COMPTYPE" ]; then
	    printf "%s\n" "-> Using ${COMPTYPE} for Squashfs compression"
	fi
	if [ -n "$KEEP" ]; then
	    printf "%s\n" "-> The session diffs will be retained"
	fi
	if [ -n "$ENSKPLST" ]; then
        printf "%\n" "-> urpmi skip list enabled"
    fi
	printf "%s\n" "###" " "
}


    FilterLogs() {
        printf "%s\n" "-> Make some helpful logs"
        #Create the header
        printf "%s\n" "" "" "RPM Install Success" " " >"$WORKDIR/rpm-install.log" 
        head -1 "$WORKDIR/install.log" | awk '{print$1"\t"$3"\t"$4"\t"$7"  "$8"  "$9"\t"$18}' >>"$WORKDIR/rpm-install.log" #1>&2 >/dev/null
        printf "%s\n" "" "" "RPM Install Failures" " " >"$WORKDIR/rpm-fail.log" 
        head -1 "$WORKDIR/install.log"  | awk '{print$1"\t"$3"\t"$4"\t"$7"  "$8"  "$9"\t"$18}' >>"$WORKDIR/rpm-fail.log" 
        cat rpm-install.log | awk '$7  ~ /0/ {print$1"\t"$3"\t"$4"\t"$7"  "$8"  "$9"\t"$18}'
        #Append the data
        cat "$WORKDIR/install.log" | awk '$7  ~ /1/  {print$1"\t"$3"\t"$4"\t\t"$7"\t "$8"\t "$9" "$18}'>> "$WORKDIR/rpm-fail.log"
        cat "$WORKDIR/install.log" | awk '$7  ~ /0/  {print$1"\t"$3"\t"$4"\t\t"$7"\t "$8"\t "$9" "$18}' >> "$WORKDIR/rpm-install.log"
        # Make a dependency failure log
        if [ -f "$WORKDIR/urpmopt.log" ]; then
         grep -hr -A1 'A requested package cannot be installed:' "$WORKDIR/urpmopt.log" | sort -u >depfail.log
        fi
        if [[ "$IN_ABF" == "1" && -f "$WORKDIR/install.log" ]]; then
         cat "$WORKDIR/rpm-fail.log"
         printf "%s\n" " " "-> DEPENDENCY FAILURES"
         cat "$WORKDIR/depfail.log"
         cat "$WORKDIR/rpm-install.log" 
        fi
        #Clean-up
 #       rm -f "$WORKDIR/install.log"
}

SavePkgLists() {
    if [[ -n "$DEVMODE" || -n "$LIST"]}; then
	$SUDO printf '%s\n' "$INSTALL_LIST" >"$WORKDIR/user_add_rpmlist"
	$SUDO printf '%s\n' "$REMOVE_LIST" >"$WORKDIR/user_rm_rpmlist"
	$SUDO printf '%s' "$INSTALL_LIST" >"$WORKDIR/rpmlist"
    fi
}


