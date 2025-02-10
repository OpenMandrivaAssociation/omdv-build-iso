#!/bin/bash

# OpenMandriva Association 2012
# Original author: Bernhard Rosenkraenzer <bero@lindev.ch>
# Modified on 2014 by: Tomasz Paweł Gajc <tpgxyz@gmail.com>
# Modified on 2015 by: Tomasz Paweł Gajc <tpgxyz@gmail.com>
# Modified on 2015 by: Colin Close <itchka@compuserve.com>
# Modified on 2015 by: Crispin Boylan <cris@beebgames.com>
# Modified on 2016 by: Tomasz Paweł Gajc <tpgxyz@gmail.com>
# Modified on 2016 by: Colin Close <itchka@compuserve.com>
# Modified on 2017 by: Colin Close <itchka@compuserve.com>
# Mofified 0n 2018 by: Colin Close <itchka@compuserve.com>
# April 2018 Major Revision to support the use of the
# dnf which replaces urpmi: Colin Close <itchka@compuserve.com>
# October 2019 Revise user mode list storage <itchka@compuserve.com>

# This tool is licensed under GPL license
#	This program is free software; you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation; either version 2 of the License, or
#	(at your option) any later version.
#
#	This program is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.
#
#	You should have received a copy of the GNU General Public License
#	along with this program; if not, write to the Free Software
#	Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#

# This tool is specified to build OpenMandriva Lx distribution ISO

main() {
	# This function which starts at the top of the file is executed first from the end of file
	# to ensure that all functions are read before the body of the script is run.
	# All global variables need to be inside the curly braces of this function.

	if [ "$#" -lt 1 ]; then
		usage_help
		exit 1
	fi

	for k in "$@"; do
		case "$k" in
		--arch=*)
			EXTARCH=${k#*=}
			;;
		--tree=*)
			TREE=${k#*=}
			case "$TREE" in
			lx4)
				TREE=4.0
				;;
			*)
				TREE="$TREE"
				;;
			esac
			;;
		--version=*)
			VERSION=${k#*=}
			if [[ "${VERSION,,}" = 'cooker' ]]; then
				VERSION="$(date +%Y.0)"
			fi
			;;
		--release_id=*)
			RELEASE_ID=${k#*=}
			;;
		--boot-kernel-type=*)
			BOOT_KERNEL_TYPE=${k#*=}
			;;
		--type=*)
			declare -l lc
			lc=${k#*=}
			case "$lc" in
			plasma|plasma6|plasma6x11|plasma-wayland|mate|cinnamon|lxqt|cutefish|cosmic|icewm|xfce|weston|gnome3|minimal|sway|budgie|edu)
				TYPE="$lc"
				;;
			*)
				TYPE=$lc
				printf "%s\n" "Creating iso named $TYPE" "You will need to provide the name of you window manager and the name of the executable to run it."
#				printf "%s\n" "$TYPE is not supported."
#				usage_help
				;;
			esac
			;;
		--displaymanager=*)
			DISPLAYMANAGER=${k#*=}
			;;
		--workdir=*)
			WORK=${k#*=}
			# Expand the tilde
			WORKDIR=${WORK/#\~/$HOME}
			;;
		--outputdir=*)
			OUTPUT=${k#*=}
			# Expand the tilde
			OUTPUTDIR=${OUTPUT/#\~/$HOME}
			;;
		--listrepodir=*)
			REPO=${k#*=}
			# Expand the tilde
			LREPODIR=${REPO/#*\~/$HOME}
			;;
		--debug)
			DEBUG=debug
			;;
		--noclean)
			NOCLEAN=noclean
			;;
		--rebuild)
			REBUILD=rebuild
			;;
		 --keep)
			KEEP=keep
			;;
		 --testrepo)
			TESTREPO=testrepo
			;;
		 --unsupprepo)
			UNSUPPREPO=unsupprepo
			;;
		 --nonfreerepo)
			NONFREEREPO=non-free
			;;
		 --repolist=*)
			ENABLEREPO=${k#*=}
			;;
		--baserepo)
			BASEREPO=baserepo
			;;
		 --isover=*)
			ISO_VER=${k#*=}
			;;
		 --auto-update)
			AUTO_UPDATE=1
			;;
		--usemirrors)
			USEMIRRORS=usemirrors
			;;
		--makelistrepo)
			MAKELISTREPO=makelistrepo
			;;
		--defaultlang=*)
			DEFAULTLANG=${k#*=}
			;;
		--defaultkbd=*)
			DEFAULTKBD=${k#*=}
			;;
		--help)
			usage_help
			;;
		*)
			printf "%s\n" "Unknown argument $k" >/dev/stderr
			usage_help
			exit 1
			;;
		esac
	done

	# Locales aren't installed in the chroot yet (obviously), don't spew errors about that
	export LANG=C
	export LC_ALL=C

	# We lose our cli variables when we invoke sudo so we save them
	# and pass them to sudo when it is started. Also the user name is needed.
	# The abf isobuilder docker instance is created with a single working directory /home/omv/iso_builder.
	# This directory must not be deleted as it contains important (but hidden) config files.
	# A support directory /home/omv/docker-iso-worker is also created this should also not be touched.
	# When an iso build request is generated from ABF the script commandline along with the data from the git repo
	# for the named branch of the script is loaded into the /home/omv/iso_builder directory and the script executed
	# from that directory. If the build completes without error a directory /home/omv/iso_builder/results is created
	# and the completed iso along with it's md5 and sha1 checksums are moved to it. These files are eventually uploaded
	# to abf for linking and display on the build results webpage. If the results are placed anywhere else they are not displayed.

	SUDOVAR=""EXTARCH="$EXTARCH "TREE="$TREE "VERSION="$VERSION "RELEASE_ID="$RELEASE_ID "TYPE="$TYPE "DISPLAYMANAGER="$DISPLAYMANAGER \
	"DEBUG="$DEBUG "NOCLEAN="$NOCLEAN "REBUILD="$REBUILD "WORKDIR="$WORKDIR "OUTPUTDIR="$OUTPUTDIR "ISO_VER="$ISO_VER "ABF="$ABF \
	"KEEP="$KEEP "TESTREPO="$TESTREPO "UNSUPPREPO="$UNSUPPREPO "NONFREEREPO="$NONFREEREPO "ENABLEREPO="$ENABLEREPO "AUTO_UPDATE="$AUTO_UPDATE \
	"ENSKPLST="$ENSKPLST " LREPODIR="$LREPODIR "USEMIRRORS="$USEMIRRORS "BASEREPO="$BASEREPO \
	"MAKELISTREPO="$MAKELISTREPO "DEFAULTLANG="$DEFAULTLANG "DEFAULTKBD="$DEFAULTKBD"


	# run only when root
	if [ "$(id -u)" != '0' ]; then
		# We need to be root for umount and friends to work...
		# NOTE the following command will only work on OMDV for the first registered user
		# this user is a member of the wheel group and has root privelidges
		exec sudo -E $(printf "%s\n" ${SUDOVAR}) $0 "$@"
		printf "%s\n" "-> Run me as root."
		exit 1
	fi

	if [ -n "$DEBUG" ]; then
		set -x
	else
		set +x
	fi

	# Set the local build prefix
	if [ -d /home/omv ] && [ -d /home/omv/docker-iso-worker ]; then
		WHO=omv
	else
		# SUDO_USER is an environment variable from the shell it gets set if you run as sudo
		WHO="$SUDO_USER"
		UHOME=/home/"$WHO"
		export UHOME
	fi

	# default definitions
	DIST=omdv
	[ -z "$EXTARCH" ] && EXTARCH="$(rpm -E '%{_target_cpu}')"
	[ -z "$EXTARCH" ] && EXTARCH="$(uname -m)"
	[ -z "${DEFAULTLANG}" ] && DEFAULTLANG="en_US.UTF-8"
	[ -z "${DEFAULTKBD}" ] && DEFAULTKBD="us"
	[ -z "${TREE}" ] && TREE=cooker
	[ -z "${VERSION}" ] && VERSION="$(date +%Y.0)"
	[ -z "${RELEASE_ID}" ] && RELEASE_ID=alpha

	ARCHEXCLUDE=""
	printf "%s\n" $EXTARCH |grep -qE "^arm" && EXTARCH=armv7hnl
	printf "%s\n" $EXTARCH |grep -qE "i.86" && EXTARCH=i686

	# Exclude 32-bit compat packages on multiarch capable systems
	case $EXTARCH in
	znver1|x86_64)
		ARCHEXCLUDE='--exclude=*.i686'
		;;
	aarch64)
		ARCHEXCLUDE='--exclude=*.armv7hnl'
		;;
	esac

	# always build free ISO
	FREE=1
	LOGDIR="."
	[ -z $ABF ] && ABF='0'
	# The functions are stored in this in the order that they are executed.
	# Functions that are not called directly are are commented out and are stored following the functions they are first called in
	# though they may be called from alternate functions.
	#

	#main  # Stared from the end of the script to ensure all functions are read
	#usage_help ~ Does what it says on the tin
	#hlpprtf # Block text formatting functions
	#optprtf # Option formatting function
	allowedOptions # Checks whether options are legal for operating environment
	setWorkdir     # Sets the workdirectory location depending on whether
# START ISO BUILD
	mkeWkingEnv    # Creates the working environment
	#RemkWorkDir   # Remake the working directory if you are rebuilding an iso.
	#SaveDaTa      # Saves useful chroot data for rebuilds
	#RestoreDaTa   # Restores data to the chroot for rebuild
	SetFileList    # Sets the current list repo paths.
	#userISONme    # Interactive menu to set user iso name and the window manager executable.
	#cfrmISONme    # Support for interactive menu.
	#cfrmWMNme     # Support for interactive menu.
	mkeREPOdir     # Creates users personal repo must always be first as it stores variables from one run to the next.
	mKeBuild_id    # Creates a unique build id.
	mkISOLabel     # Creates the iso labelling data and the UUIDS.
	showInfo       # Shows major options chosen.
	getPkgList     # Gets the package lists from git hub from branch set by --isover.
	CarryOn        # An entry point for the user build setup.
} #End of main

########################
#   Start functions    #
########################
# TODO:
# Test --auto-update switch
# Add  --auto-upgrade
# Investigate why we can't mount our isos in plasma

CarryOn() {
	InstallRepos       # Installs the repo rpms if they are not already installed
	updateSystem       # Updates the system rpms if not already updated
	createChroot       # Creates chroot (proc dirs and mounts) Despatches to following functions
	#mkOmSpin          # Creates an iso in the ABF environment
	#getIncFiles       # Recursively gets all the files included in a top level list and returns it in a variable
	#createPkgList     # Creates a package list from a list of package list files and returns it in a variable.
	#mkUpdateChroot    # Installs or updates the files in the chroot
	#MyAdd             # Local users package list for adding files to build
	#MyRmv             # Local users package list for removing files
	createInitrd       # Creates the initrds. This function is able to use two different kernels and gives boot entries for both
	createMemDisk      # Creates a memdisk for embedding in the iso-build-lists.
	createUEFI         # Creates a bootable UEFI image and installs startup.nsh to fix start-up in VirtualBox hypervisor
	setupGrub2         # Configure and set up grub2
	setupISOenv        # Move files to ISO build directories
	ClnShad            # Clean out passwd locks from the chroots /etc
	InstallRepos       # Reinstall the repos so that the defaults are correct
	createSquash       # Create a squashed filesystem from the built chroot
	buildIso           # use xorriso to build an iso from the boot files and the squashfs
	postBuild          # Iso management md5sums etc
	#umountAll         # Function for unmounting all potentially mounted directories and devices
	#errorCatch        # Called on error calls umountAll and gives an exit message
	FilterLogs         # Provides various logs. When parallel is used gives a list of packages that failed to install
	#END
}

usage_help() {
	if [ -z "$EXTARCH" ] && [ -z "$TREE" ] && [ -z "$VERSION" ] && [ -z "$RELEASE_ID" ] && [ -z "$TYPE" ] && [ -z "$DISPLAYMANAGER" ]; then
		printf "%b\n" ""
		printf "%b\t" "Please run script with arguments" "usage $0 [options]"
		printf "%b\n" "" "\t\t\t\t${ulon}${bold}GENERAL OPTIONS${normal}"

		optprtf "--arch=     " "Architecture of packages: i686, x86_64, znver1"
		optprtf "--tree=     " "Branch of software repository: cooker, lx4"
		optprtf "--version=" "Version for software repository: 4.0"
		optprtf "--release_id=" "Release identifer: alpha, beta, rc, final"
		optprtf "--type=     " "User environment type desired on ISO: plasma, plasma6, mate, budgie, lxqt, cutefish, cosmic, icewm, xfce, weston, gnome3, edu, minimal, user-type. ${ulon}${bold}NOTE:${normal} When type is set to ${bold}a user chosen name${normal} an interactive session will be invoked where the user will be asked for the window manager desktop file and the command required to start the desired window manager. Both entries must be valid for a proper build of the new iso. No error check is performed on the values entered. Th ese values are saved in a sub-directory of the list repo directory and are restored on each run."
		hlpprtf "\t\t\tBy default the system build a minimal iso from a list repo with the user selected name. Subsequently the user may add additional include lines, packages or local filenames directories for inclusion to the my.add file in the repository named in the first step. The list repo is created ahead of the build so the script will exit after creating the intial repo to allow the user to add packages or includes to the my.add file before building the iso. On subsequent runs the program will not exit but continue on to build the iso. See also the --makelistrepo option. Switching between user created repos is accomplished by setting the --listrepodir to the desired directory."
		printf "%b" "--displaymanager=" "\tDisplay Manager used in desktop environemt: sddm , none\n"
		optprtf "--workdir=" "Set directory where ISO will be build The default is ~/omdv-buildchroot-<arch>"
		optprtf "--outputdir=" "Set destination directory to where put final ISO file. The default is ~/omdv-buildchroot-<arch>/results"
		printf "%b" "--boot-kernel-type" "\tKernel to use for booting, if different from standard kernel. Grub's menu will offer alternate kernels for booting\n"
		optprtf "--auto-update" "Update the build chroot to the latest package versions. Saves rebuilding. Runs dnf --refresh distro-sync on the chroot"
		printf -vl "%${COLUMNS:-`tput cols 2>&-||echo 80`}s\n" && echo ${l// /-}
		printf "%b\n" "\t\t\t\t${ulon}${bold}REPOSITORY MANAGEMENT${normal}"
		hlpprtf "\t\t\tSeveral options allow the selection of additional repositories in addition to the default (main). Please note that is the following options are used the selected repositories will be left enabled on the iso. If you just want the default repositories on the iso use the --baserepo switch in addition to the other selectors."
		optprtf "--testrepo" "Enables the testing repo for the main repository"
		optprtf "--unsupprepo" "Enables the extra repo"
		optprtf "--nonfreerepo" "Enables the non-free repo"
		optprtf "--repolist" "Allows a list of comma separated repoid's to enable.  i.e. --repolist=extra,updates,restricted To obtain a list of repo-ids run 'dnf --quiet repolist --all' in a terminal. There is also a list in the documentation"
		optprtf "--baserepo" "Resets the above options to the default for the repo group (rock, rolling, cooker)"
		printf -vl "%${COLUMNS:-`tput cols 2>&-||echo 80`}s\n" && echo ${l// /-}
		printf "%b\n" "\t\t\t\t${ulon}${bold}USER BUILDS - REMASTERING${normal}"
		printf "%b\n"
		hlpprtf "\t\t\tProvision is made for custom builds in the form of two files in the package list directories. These are my.add and my.rmv you can add packages names to either of these files and they will be added or removed. You may also add full paths to local rpm files and these will be installed as well. Including other package lists is also supported see the package list files with the folloing include syntax | %include .///omdv-<listname>.lst |. The my.rmv file can be used to temporarily remove packages from the package lists that are failing to install or are simple not required without the need to modify the original lists. The files are stored in a directory which is set up as a git repository; each time the script is run this directory is checked for changes and if any are found they committed to the git repository using a commmit message which contains the build-id and the number of times the script has been run for that build id thus providing a full record of the session. Note that changes to ALL the files are recorded and it is not mandatory that you use my.add or my.rmv it is just more convenient. my.rmv is the only way to remove packages from the chroot when using the --noclean and --rebuild options. To enable the user to create different custom builds and return to them easily the --lrepodir=<dirpath> option is provided. The dirpath defaults to ~/<user_name>s-user-iso but may be pointed to any directory path in the users home directory. The directory once created is never deleted by the script. It is for the user to remove redundant data directories. The script records the last used data directory and restores the content to the chroot unless --lrepodir is set to another value; then a new directory is created (if it does not already exist) with files downloaded from the github repository corresponding to the repository you wish to build against.\n"
		optprtf "--lrepodir=" "The lrepodir option sets the path to the storage directory for the package lists and other iso files. Once set the path for this directory will be remembered until the value of the lrepodir dir is changedl This initiates a fresh build with virgin files from the OMA repos."
		optprtf "--noclean" "Do not clean build chroot and keep cached rpms. Updates chroot with new packages. Option will not re-install the packages it will only retain them"
		printf "%b\n\n" "\t\t\tFor the following options you must have built an iso using the --noclean option before they can be applied"
		optprtf "--rebuild" "Recreates the build chroot and rebuilds from cached rpms and supplementary files. This allows a developer to modify the ""fixed"" iso setup files and preserve them from one run to the next"
		optprtf "--isover" "Allows the user to fetch a personal repository of build lists from their own repository. Currently the repository must reside on github as a branch of the omdv-build-iso repository"
		optprtf  "--usemirrors" "Use the mirrorlists to find packages; this option is only intended for use when the main ABF repositories are unavailable. It's possible that the iso will be built with out of date packages"
		printf -vl "%${COLUMNS:-`tput cols 2>&-||echo 80`}s\n" && echo ${l// /-}
		printf "%6b\n" "\t\t\t\t${ulon}${bold}DEVELOPER OPTIONS${normal}"
		optprtf "--debug   " "Enable debug output basically enables set -x. This option also allows ABF=1 to be used loacally for testing"
		optprtf "--compressor" "This option allows a choice for the compressor to be used when the mksquashfs file is created. Valid choices are gzip, xz, lzo, lz4 and zstd."
		optprtf "--keep  " "Retains only the build lists from one run to another. This means that if you modify the package lists within the working directory (usually omdv-build-chroot-<arch>) they will be restored unconditionally on the next run irrespective of any other flags. This can be used to create lists for new compilations. The build lists are stored in a git repository and each time there is a change a commit is performed thus keeping a record of the users session."
		optprtf "--makelistrepo" "Just make a list repo if one does not already exist the --listrepodir, --arch and --tree options must be set. Optionally the --isover option may be set to direct the script to an alternative branch on GitHub. The script will create the repo and then exit"
		printf "%b\n"

		printf "%b\n" "\t${ulon}${bold}For example:${normal}" " "
		printf "%b\n" "\tBuild a x86_64 bit iso containg the plasma desktop with sddm as the display manager from the cooker repository"
		printf "%b\n" "\t${bold}omdv-build-iso.sh --arch=x86_64 --tree=cooker --version=4.0 --release_id=alpha --type=plasma --displaymanager=sddm${normal}" " "
		hlpprtf "\tCreate a user iso from the rolling tree using list files from the repository \"addrepos\" using the xz compressor to create the squashed filesystem. With this comman the user will enter an interactive session during which the iso will be named and the display manager chosen. On exit from the interactive session a user named repository will be set up and then the program will exit to allow the addition of data to indicate which packages to use to builds the new iso. When this is complete running the script a second time will build the users iso."
		printf "%b\n" "\t${bold}omdv-build-iso.sh --arch=x86_64 --tree=rolling --version=4.0 --release_id=alpha --type=user  --isover=addrepos --compressor=xz --displaymanager=sddm${normal}"
		printf "%b\n" "\tNote that when --type is set to user the user may select their own ISO name during the execution of the script" " "
		printf "%b\n" "\tFor detailed usage instructions consult the files in /usr/share/omdv-build-iso/docs/"
		printf "%b\n" "\tExiting."
		exit 1
	else
		return 0
	fi
}

hlpprtf() {
#Indents text; add tabs '\t' at start of text to control indent
COLUMNS=$(tput cols)
FINAL=$(( COLUMNS - 80 ))
OP=$(printf "%b\n\t\t\t" "$1" | fmt -w "$FINAL")
printf "%s\n" "$OP"
}

optprtf() {
#Formats text for formatting program options in the help
COLUMNS=$(tput cols)
FINAL=$(( COLUMNS - 100 ))
OPT=$(printf "%s" "$1")
OPT1=$(printf "%b" "\t\t$2" | fmt -w  "$FINAL" -c)
printf "%s" "$OPT"; printf "%s\n" "${OPT1//$'\n'$'\t'/$'\n'$'\t'$'\t'}"
}
bold=$(tput bold)
normal=$(tput sgr0)
ulon='\033[4m' # set underline on

allowedOptions() {
	if [ "$ABF" = '1' ] || [ -n "$ABF" ]; then
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
		if [ -n "$NOCLEAN" ] && [ -n "$REBUILD" ]; then
			printf "%s\n" "-> You cannot use --noclean and --rebuild together"
			exit 1
		fi
		if [ -n "$REBUILD" ]; then
			printf "%s\n" "-> You cannot use --rebuild inside ABF (https://abf.openmandriva.org)"
			exit 1
		fi
	else
		ABF=0
	fi
}

setWorkdir() {
	# Set the $WORKDIR
	# If ABF=1 then $WORKDIR codes to /bin on a local system so if you try and test with ABF=1 /bin is rm -rf ed.
	# To avoid this and to allow testing use the --debug flag to indicate that the default ABF $WORKDIR path should not be used
	# To ensure that the WORKDIR does not get set to /usr/bin if the script is started we check the WORKDIR path used by abf and
	# To allow testing the default ABF WORKDIR is set to a different path if the DEBUG option is set and the user is non-root.
	if [ "$ABF" = '0' ]; then
		if [ -z "$WORKDIR" ]; then
			WORKDIR="$UHOME/omdv-build-chroot-$EXTARCH"
			export WORKDIR
		fi
		# Make the directory for saving data between runs
		mkdir -p "${UHOME}"/ISOBUILD
		BUILDSAV="${UHOME}"/ISOBUILD
	else
		if [ "$ABF" = '1'  ] && [ -d '/home/omv/docker-iso-worker' ]; then
			# We really are in ABF
			WORKDIR="$(realpath $(dirname "$0"))"
		elif [ -n "$DEBUG" ]; then
			if [ -z "$WORKDIR" ]; then
				WORKDIR="$UHOME/omdv-build-chroot-$EXTARCH"
			fi
			printf "%s\n" "-> Debugging ABF build locally"
		else
			printf "%s\n" "-> DO NOT RUN THIS SCRIPT WITH ABF=1 ON A LOCAL SYSTEM WITHOUT SETTING THE DEBUG OPTION"
			exit 1
		fi
	fi
	printf "%s\n" "-> The work directory is $WORKDIR"
	# Define these earlier so that files can be moved easily for the various save options
	# this is where rpms are installed
	CHROOTNAME="$WORKDIR/BASE"
	# this is where ISO files are created
	ISOROOTNAME="$WORKDIR/ISO"
	mkdir -p ${CHROOTNAME}
	mkdir -p ${ISOROOTNAME}
}

mkeWkingEnv() {
	# User mode allows three modes of operation.
	# All user modes rely on the script being run with no user options to generate  the initial chroot.
	# The options are:-
	# --noclean Where the chroot (once generated) is reused
	# --rebuild. Where the chroot/BASE is rebuilt from the initial rpm downloads
	# Run without either option and with --workdir pointing to the chroot
	# the script will delete the existing chroot and create a new one.

	# For all modes any changes made to the pkg lists are implemented and recorded
	# User mode also generates a series of diffs as a record of the multiple sessions.
	# The --keep option allow these to be retained for subsequent sessions

	if [ "$ABF" = '0' ]; then
		if [ -n "$NOCLEAN" ] && [ -d "$WORKDIR" ]; then #if NOCLEAN option selected then retain the chroot.
			if [ ! -d "$COMMITDIR"/sessrec ]; then
				touch "$WORKDIR"/.new
			else
				printf "%s\n" "-> You have chosen not to clean the base installation" \
					"If your build chroot becomes corrupted you may want"\
					"to take advantage of the 'rebuild' option to delete the corrupted files"\
					"and build a new base installation." \
					"This will be faster than dowloading the rpm packages again"
				# The .new file will have been removed restore it for the next build.
				touch "$WORKDIR"/.new
			fi
			# Note need to clean out grub uuid files here and maybe others
		else
			if [ -n "$REBUILD" ] && [ ! -d "$WORKDIR" ]; then
				printf "%s\n" "-> Error the $WORKDIR does not exist there is nothing to rebuild." \
					"-> You must run  your command with the --noclean option set to create something to rebuild."
				printf "%s\n" "-> No base chroot exists...creating one"
				RemkWorkDir
			elif [ -d "$WORKDIR" ]; then
				SaveDaTa     # Save data does not save the package lists sessions unless the --keep option is chosen
				# It only saves the dnf rpm cache and the files in the dracut,grub2, boot, data and extraconfig directories
				# which may of may not have been modified by ther user
				RestoreDaTa  # RestoreDaTa also cleans and recreates the $WORKDIR
			fi
		fi
	else
		# Expressly for debugging ABF=1 outside of the ABF builder
		if [ "$ABF" = '1' ] && [ -n "$DEBUG" ] && [ "$WHO" != 'omv' ] && [ -n "$NOCLEAN" ]; then
			touch "$WORKDIR"/.new
			printf "%s\n" "Using noclean inside abf mode debug instance"
		else
			RemkWorkDir
		fi
	fi
}


RemkWorkDir() {

	printf "%s\n" "-> Remaking directories"
	mkdir -p ${WORKDIR}
	# Create the mount points
	mkdir -p ${CHROOTNAME}/proc ${CHROOTNAME}/sys ${CHROOTNAME}/dev ${CHROOTNAME}/dev/pts
	# Create the ISO directory
	mkdir -p ${ISOROOTNAME}
	touch ${WORKDIR}/.new
}

SaveDaTa() {
	printf "%s\n" "-> Saving config data"
	if [ -n "$KEEP" ] || [ -n "$REBUILD" ]; then
		printf "%s\n" "-> Saving system files for rebuild"
		mv "$WORKDIR/dracut" "$BUILDSAV/dracut"
		mv "$WORKDIR/grub2" "$BUILDSAV/grub2"
		mv "$WORKDIR/boot" "$BUILDSAV/boot"
		mv "$WORKDIR/data" "$BUILDSAV/data"
		mv "$WORKDIR/extraconfig" "$BUILDSAV/extraconfig"
		printf "%s\n" "-> Saving rpms for rebuild"
		mv "$CHROOTNAME/var/cache/dnf/" "$BUILDSAV/dnf"
		mv "$CHROOTNAME/etc/dnf/" "$BUILDSAV/etc/dnf"
	fi
}

RestoreDaTa() {
	printf "%s\n"  "-> Cleaning WORKDIR"
	# Re-creates the WORKDIR and populates it with saved data
	# In the case of a rebuild the $CHROOTNAME dir is recreated and the saved rpm cache is restored to it..
	rm -rf "$WORKDIR"
	mkdir -p "$WORKDIR"

	if [ -n "$KEEP" ] || [ -n "$REBUILD" ]; then
		printf "%s\n" "-> Restoring system files"
		mv "$BUILDSAV/dracut" "$WORKDIR/dracut"
		mv "$BUILDSAV/grub2" "$WORKDIR/grub2"
		mv "$BUILDSAV/boot" "$WORKDIR/boot"
		mv "$BUILDSAV/data" "$WORKDIR/data"
		mv "$BUILDSAV/extraconfig" "$WORKDIR/extraconfig"
	fi
	if [ -n "$REBUILD" ]; then
		printf "%s\n" "-> Restoring rpms for new build"
		#Remake needed directories
		mkdir -p "$CHROOTNAME/proc" "$CHROOTNAME/sys" "$CHROOTNAME/dev/pts"
		mkdir -p "$CHROOTNAME/var/lib/rpm" #For the rpmdb
		mkdir -p "$CHROOTNAME/var/cache/dnf"
		mv "$BUILDSAV/dnf" "$CHROOTNAME/var/cache/"
		mv "$BUILDSAV/etc/dnf" "$CHROOTNAME/etc/dnf/"
	else
		# Clean out the dnf dir
		cd "$BUILDSAV"||exit
		if [ -d dnf ]; then
		/bin/rm -r ./dnf
		fi
	fi
	touch "$WORKDIR/.new"
}

SetFileList() {
	# Assign the config build list
	# This could work by just checking by checking whether the provided entry exists in the list of TYPES if it does not then this must be a user chosen name.
	# we would still call the interactive session but the constraint on the naming would be removed.

	case "$TYPE" in
	plasma|plasma6|plasma6x11|plasma-wayland|mate|cinnamon|lxqt|cutefish|cosmic|icewm|xfce|weston|gnome3|minimal|sway|budgie|edu)
		NEWTYPE=error
		;;
	*)
		NEWTYPE="$TYPE"
		;;
	esac
	if [ "$NEWTYPE" = "error" ]; then
		if [ "$TYPE" = 'plasma-wayland' ]; then
			FILELISTS="$WORKDIR/iso-pkg-lists-${TREE,,}/${DIST,,}-plasma.lst"
		elif [ "$TYPE" = 'plasma6x11' ]; then
			FILELISTS="$WORKDIR/iso-pkg-lists-${TREE,,}/${DIST,,}-plasma6x11.lst"
		elif [ "$TYPE" = 'plasma6' ]; then
			FILELISTS="$WORKDIR/iso-pkg-lists-${TREE,,}/${DIST,,}-plasma6wayland.lst"
		else
			FILELISTS="$WORKDIR/iso-pkg-lists-${TREE,,}/${DIST,,}-${TYPE,,}.lst"

		fi
	elif [ "$NEWTYPE" != "error" ] && [ $ABF = '1' ]; then
		printf "%s\n" "You cannot create your own isos within ABF." "Please enter a legal value" "You may use the --isover=<branch name> i.e. A branch in the git repository of omdv-build-iso to pull in revised compilations of the standard lists."
		errorCatch
	fi
}

userDSKTPNme() {
	# Interactive menu for managing the iso name and the window manager executable
	# Works along with the two other functions cfrmISONme and cfrmWMNme set and save
	# the iso and window manager names. The names are save in the list repo under the sessrec
	# directory as .wmdeskname and .wmname.

	if [ -f "$COMMITDIR"/sessrec/.wmdeskname ]; then
		printf "%s\n" "Loading Iso name"
		WMDESK="$(< "${COMMITDIR}"/sessrec/.wmdeskname)"
	else
		printf "%s\n" " " "Please give a name to your iso e.g Enlight" "This will also be the name of the WM desktop file associated with it"
		read -r in1
		printf "%s\n" "$in1"
		if [ -n "$in1" ]; then
			printf "%s\n" "The  will be $in1" "Is this correct y or n ?"
			cfrmDSKTPNme
		fi
	fi
	if [ -f "$COMMITDIR"/sessrec/.wmname ]; then
		printf "%s\n" "Loading window manager name"
		WMNAME="$(< "${COMMITDIR}"/sessrec/.wmname)"
	else
		printf "%s\n" "Please provide the name of the window manager executable you wish to use for your desktop session."
		read -r in1
		printf "%s\n" "$in1"
		if [ -n "$in1" ]; then
			printf "%s\n" "The WM executable will be $in1" "Is this correct y or n ?"
				cfrmWMNme
		fi
		printf "%s\n" "Your window manager executable is named $WMNAME" " "
	fi
}

cfrmDSKTPNme() {
	read -r in2
	printf "%s\n" $in2
	if [ $in2 = 'yes' ] || [ $in2 = 'y' ]; then
		WMDESK="$in1"
		printf "%s\n" "Your iso and window manager desktop file name will be $WMDESK" " "
		return 0
	fi
	if [ $in2 = 'no' ] || [ $in2 = 'n' ]; then
		userDSKTPNme
	fi
}

cfrmWMNme() {
	read -r in2
	echo $in2
	if [ $in2 = 'yes' ] || [ $in2 = 'y' ]; then
		WMNAME="$in1"
		printf "%s\n" "The WM executable will be $in1" "Is this correct y or n ?"
		return 0
	fi
	if [ $in2 = 'no' ] || [ $in2 = 'n' ]; then
		userDSKTPNme
	fi
}

mkeREPOdir() {
	# This function create the directory pointed to by the --listrepodir=< repo name> option
	# if it does not exist. A small file (.repo) is written to the users home directory.
	# This file is read on startup (if it exists) and the LREPODIR  or NEWTYPE is set to the value contained in it
	# One of these variables is used to set the COMMITDIR variable dependent on whether a standard or user iso is to be built.
	# The variable that determines this is the TYPE variable.
	# If the directory listed in the .repo file does not exit then it is created.
	if [  "$ABF" = '0' ]; then
		if [ -n "$LREPODIR" ]; then
			if [ "$LREPODIR" == "$(< "${UHOME}"/.rpodir)" ] && [ -d "$UHOME"/"$LREPODIR" ]; then
				COMMITDIR="$UHOME"/"$LREPODIR"
				printf "%s\n" "The package lists for this build are stored in $COMMITDIR found 1"
			else
				mkdir -p "$UHOME"/"$LREPODIR"/sessrec
				printf "%s\n" "$LREPODIR" > "$UHOME"/.rpodir
				COMMITDIR="$UHOME"/"$LREPODIR"
				printf "%s\n" "The package lists for this build are stored in $COMMITDIR found 2"
			fi
		elif [ -n "$NEWTYPE" ] && [ "$NEWTYPE" != "error" ] && [ ! -d "$UHOME"/"$NEWTYPE"/iso-pkg-lists-"${TREE,,}"/omdv-minimal.lst ]; then
			mkdir -p "$UHOME"/"$NEWTYPE"/sessrec
			echo "$NEWTYPE" > "${UHOME}"/.rpodir
			COMMITDIR="$UHOME"/"$NEWTYPE"
			printf "%s\n" "The package lists for this build are stored in $COMMITDIR found 4"
		elif [ -f "$UHOME"/.rpodir ]; then
			LREPODIR="$(< "${UHOME}"/.rpodir)"
			printf "%s\n" "$LREPODIR"
			COMMITDIR="$UHOME"/"$LREPODIR"
			printf "%s\n" "The package lists for this build are stored in $COMMITDIR found 3"
		else
			LREPODIR="$WHO"s-user-iso
			mkdir -p "$UHOME"/"$LREPODIR"/sessrec
			echo "$LREPODIR" > "${UHOME}"/.rpodir
			COMMITDIR="$UHOME"/"$LREPODIR"
			printf "%s\n" "The package lists for this build are stored in $COMMITDIR found 5"
		fi
	else
		cd "$WORKDIR" || exit
		COMMITDIR="${WORKDIR}"
	fi
}

mKeBuild_id() {
	# Makes a unique? build id
	printf "%s\n" "Create the BUILD_ID"
	if [ "$ABF" = '0' ]; then
		if [ -f "$COMMITDIR"/sessrec/.build_id ]; then
			# The BUILD_ID has already been saved. Used to create commit messages.
			BUILD_ID=$(cat "$COMMITDIR"/sessrec/.build_id)
		else
			BUILD_ID=$(date +%H%M)
			printf "%s\n" ${BUILD_ID} > "$COMMITDIR"/sessrec/.build_id
		fi
	else
		[ -z "$BUILD_ID" ] && BUILD_ID=$(date +%H%M)
	fi
}

mkISOLabel() {
	# UUID Generation. xorriso needs a string of 16 asci digits.
	# grub2 needs dashes to separate the fields..
	GRUB_UUID="$(date -u +%Y-%m-%d-%H-%M-%S-00)"
	ISO_DATE="$(printf "%s" "$GRUB_UUID" | sed -e s/-//g)"
	# in case when i386 is passed, fall back to i686
	[ "$EXTARCH" = 'i386' ] && EXTARCH=i686
	[ "$EXTARCH" = 'i586' ] && EXTARCH=i686

	if [ "${RELEASE_ID,,}" = 'final' ]; then
		PRODUCT_ID="OpenMandrivaLx.$VERSION"
	elif  [ "${RELEASE_ID,,}" = 'snapshot' ]; then
		RELEASE_ID="$RELEASE_ID.$(date +%Y%m%d).$BUILD_ID"
	elif  [ "${RELEASE_ID,,}" = 'beta' ]; then
		RELEASE_ID="$RELEASE_ID.$(date +%Y%m%d).$BUILD_ID"
	elif [ "${RELEASE_ID,,}" = 'alpha' ]; then
		RELEASE_ID="$RELEASE_ID.$(date +%Y%m%d).$BUILD_ID"
	fi
	PRODUCT_ID="OpenMandrivaLx.$VERSION-$RELEASE_ID-$TYPE"
	printf "%s" "$PRODUCT_ID"

	LABEL="$PRODUCT_ID.$EXTARCH"
	[ $(printf "%s\n" "$LABEL" | wc -m) -gt 32 ] && LABEL="OpenMandrivaLx_$VERSION"
	[ $(printf "%s\n" "$LABEL" | wc -m) -gt 32 ] && LABEL="$(printf "%s\n" "$LABEL" |cut -b1-32)"
}

showInfo() {
	echo $'###\n'
	printf "%s\n" "Building ISO with arguments:"
	printf "%s\n" "Distribution is $DIST"
	printf "%s\n" "Architecture for ISO is $EXTARCH"
	printf "%s\n" "Tree is $TREE"
	printf "%s\n" "Version is $VERSION"
	printf "%s\n" "Release ID is $RELEASE_ID"
	printf "%s\n" "Type is $TYPE"
	if [ "${TYPE,,}" = 'minimal' ]; then
	    printf "%s\n" "-> No display manager for minimal ISO."
	else
	    printf "%s\n" "Display Manager is $DISPLAYMANAGER"
	fi
	printf "%s\n" "ISO label is $LABEL"
	printf "%s\n" "Build ID is $BUILD_ID"
	printf "%s\n" "Working directory is $WORKDIR"
	printf "%s\n" "isobuilder is running on $(hostname)"
	if  [ -n "$REBUILD" ]; then
		printf "%s\n" "-> All rpms will be re-installed"
	elif [ -n "$NOCLEAN" ]; then
		printf "%s\n" "-> Installed rpms will be updated"
	fi
	if [ -n "$DEBUG" ]; then
		printf "%s\n" "-> Debugging enabled"
	fi
	if [ -n "$KEEP" ]; then
		printf "%s\n" "-> The session diffs will be retained"
	fi
	printf "%s\n" "###" " "
}

getPkgList() {
	# Package list handling has two modes. When the script is run on ABF the package lists are obtained from the git repos.
	# The branch used will can be changed by using the --isover switch to get the lists from a different branch of the repo.
	# When operated outside of ABF it is assumed that the user will wish to modify the lists to create their own custom iso.
	# In this case the package lists are initially downloaded from GitHub and the versions that match the repo given on the command line
	# is copied to the directory pointed to by the LREPODIR variable. The LREPODIR variable is automatically set to a default if the user
	# does not provide a name. The directory name is stored in an hidden file .rpodir in the users home directory.
	# A git repository is created in the LREPODIR and an an initial commit made with an automatically generated commit message which
	# contains the "Build ID" and a session count which uniquely labels each commit.
	# Should the user alter the files then on a subsequent iso build the files from the directory pointed to by the LREPODIR variable
	# will be copied to the current working directory and a commit generated for the users changes.
	# If the user wishes to create a new spin they can achieve this by setting the --listrepodir commandline option to a new directory
	# where a new set of default files with their git repo will be created. Should the user wish to switch to their original iso using that directory name
	# with the --listrepodir option will switch the default back to the original set of build lists. The number of directories is effectively unlimited.

	if [ ! -d "$WORKDIR/iso-pkg-lists-${TREE,,}" ]; then
		printf "%s\n" "-> Could not find $WORKDIR/iso-pkg-lists-${TREE,,}. Downloading from GitHub."
		# download iso packages lists from https://github.com
		# GitHub doesn't support git archive so we have to jump through hoops and get more file than we need
		if [ -n "$ISO_VER" ]; then
			export GIT_BRNCH="$ISO_VER"
		elif [ ${TREE,,} == "cooker" ]; then
			export GIT_BRNCH=master
		else
			export GIT_BRNCH=${TREE,,}
			# ISO_VER defaults to user build entry
		fi
		cd "$WORKDIR" || exit
		EX_PREF=./
		EXCLUDE_LIST="--exclude ${EX_PREF}.abf.yml --exclude ${EX_PREF}ChangeLog --exclude ${EX_PREF}Developer_Info --exclude ${EX_PREF}Makefile --exclude ${EX_PREF}README --exclude ${EX_PREF}TODO --exclude ${EX_PREF}omdv-build-iso.sh --exclude ${EX_PREF}omdv-build-iso.spec --exclude ${EX_PREF}docs/*  --exclude ${EX_PREF}tools/* --exclude ${EX_PREF}ancient/*"
		wget -qO- https://github.com/OpenMandrivaAssociation/omdv-build-iso/archive/"${GIT_BRNCH}".zip | bsdtar -xvf- ${EXCLUDE_LIST} --strip-components 1
		if [ ! -e "$FILELISTS" ]; then
			printf "%s\n" "-> $FILELISTS does not exist. Exiting"
			errorCatch
		fi
	fi
}

InstallRepos() {
	# There are now different rpms available for cooker and release so these can be used to directly install the the repo files. The original function is kept just
	# in case we need to revert to git again for the repo files.
	#Get the repo files
	if [ -e "$WORKDIR"/.new ]; then
		PKGS=http://abf-downloads.openmandriva.org/"$TREE"/repository/$EXTARCH/main/release/
		cd "$WORKDIR" || exit
		curl -s -L $PKGS |grep '^<a' |cut -d'"' -f2 >PACKAGES
		PACKAGES="distro-release-repos distro-release-repos-keys distro-release-repos-pkgprefs dnf-data"
		for i in $PACKAGES; do
			P=$(grep "^$i-[0-9].*" PACKAGES |tail -n1)
			if [ "$?" != '0' ]; then
				printf "%s\n" "Can't find $TREE version of $i, please report"
				exit 1
			fi
			wget $PKGS/$P
		done
	fi

	if [ -e "$WORKDIR"/.new ]; then
		rpm -Uvh --root "$CHROOTNAME" --force --oldpackage --nodeps --ignorearch *.rpm
	else
		/bin/rm -rf "$CHROOTNAME"/etc/yum.repos.d/*.repo "$CHROOTNAME"/etc/dnf/dnf.conf
		rpm --reinstall -vh --root "$CHROOTNAME" --replacefiles --nodeps --ignorearch  *.rpm
	fi

	if [ -e "$CHROOTNAME/etc/yum.repos.d" ]; then ## we may hit ! -e that .new thing
		ls -l $CHROOTNAME/etc/yum.repos.d
	else
		printf "%s\n"  "/etc/yum.repos.d not present"
	fi

	# Use the master repository, not mirrors
	if [ -e "$WORKDIR"/.new ]; then
		if [ -n "$USEMIRRORS" ]; then
			printf "->WARNING<- YOU HAVE ELECTED TO DOWNLOAD THE PACKAGES FOR THIS BUILD FROM A MIRROR. PACKAGE VERSIONS MAY NOT BE UP TO DATE"
		else
			sed -i -e 's,^mirrorlist=,#mirrorlist=,g;s,^# baseurl=,baseurl=,g' $CHROOTNAME/etc/yum.repos.d/*.repo
			# Using perl instead of sed below because we want to remove the newline
			perl -p -i -e 's|http://mirror.*, ||' $CHROOTNAME/etc/yum.repos.d/*.repo
			perl -p -i -e 's|https://mirror.*, ||' $CHROOTNAME/etc/yum.repos.d/*.repo
			perl -p -i -e 's|http://mirror[^ ]*$||' $CHROOTNAME/etc/yum.repos.d/*.repo
			perl -p -i -e 's|https://mirror[^ ]*$||' $CHROOTNAME/etc/yum.repos.d/*.repo
		fi
		# we must make sure that the rpmcache is retained
		printf "%s\n" "keepcache=1" >> $CHROOTNAME/etc/dnf/dnf.conf
		# This setting will be overwritten when the repos are re-installed at the end; however
		# because the repo rpms are installed with rpm -Uvh the cache wont be cleared as dnf won't be run so the vache must be removed.
	fi

	DNFCONF_TREE="$TREE"
	if echo $TREE |grep -qE '^[0-9]'; then
		DNFCONF_TREE="release"
	fi

	#Check the repofiles and gpg keys exist in chroot
	if [ ! -s "$CHROOTNAME/etc/yum.repos.d/openmandriva-cooker-${EXTARCH}.repo" ] || [ ! -s "$CHROOTNAME/etc/pki/rpm-gpg/RPM-GPG-KEY-OpenMandriva" ]; then
		printf "%s\n"  "Repo dir bad install."
		errorCatch
	else
		printf "%s\n" "Repository and GPG files installed sucessfully."
		/bin/rm -rf $CHROOTNAME/etc/yum.repos.d/*.rpmnew
	fi

	if [ -e "$WORKDIR"/.new ]; then
		# First make sure cooker is disabled
		dnf --installroot="$CHROOTNAME" config-manager --disable cooker-"$EXTARCH"
		# Rock too -- at release time, rock and $DNFCONF_TREE should be
		# the same anyway
		dnf --installroot="$CHROOTNAME" config-manager --disable rock-*"$EXTARCH"
		# Then enable the main repo of the chosen tree
		dnf --installroot="$CHROOTNAME" config-manager --enable "$DNFCONF_TREE"-"$EXTARCH"
		# And the corresponding updates repository (allow this to fail, because there
		# is no rolling/updates or cooker/updates)
		dnf --installroot="$CHROOTNAME" config-manager --enable "$DNFCONF_TREE"-updates-"$EXTARCH" || :
	else
		# Clean up
		/bin/rm -rf "$WORKDIR"/*.rpm
	fi

	# This must only happen on the second invocatiom.
	if [ -n "$BASEREPO" ]; then
		printf "%s\n" "->Enabling the main repo only"
	else
		if [ -n "$UNSUPPREPO" ]; then
			dnf --installroot="$CHROOTNAME" config-manager --enable "$DNFCONF_TREE"-"$EXTARCH"-extra
			# And the corresponding updates repository (allow this to fail, because there
			# is no rolling/updates or cooker/updates)
			dnf --installroot="$CHROOTNAME" config-manager --enable "$DNFCONF_TREE"-updates-"$EXTARCH"-extra || :
		fi
		if [ -n "$NONFREEREPO" ]; then
			dnf --installroot="$CHROOTNAME" config-manager --enable "$DNFCONF_TREE"-"$EXTARCH"-non-free
			# And the corresponding updates repository (allow this to fail, because there
			# is no rolling/updates or cooker/updates)
			dnf --installroot="$CHROOTNAME" config-manager --enable "$DNFCONF_TREE"-updates-"$EXTARCH"-non-free || :
		fi
		# Some pre-processing required here because of the structure of repoid's
		if [ -n "$ENABLEREPO" ]; then
			ENABLEREPO=$(tr "," " " <<< $ENABLEREPO)
			#for rpo in ${ENABLEREPO//,/]; do
			dnf --installroot="$CHROOTNAME" config-manager --releasever=${TREE} --enable ${ENABLEREPO}
			#done
		fi

		if [ -n "$TESTREPO" ]; then
			dnf --installroot="$CHROOTNAME" config-manager --enable "$DNFCONF_TREE"-testing-"$EXTARCH"
		fi
	fi
	# DO NOT EVER enable non-free repos for firmware again , but move that firmware over if *needed*
}

updateSystem() {
	# Remember it's the local system we are updating here not the chroot

	ARCH="$(rpm -E '%{_target_cpu}')"
	HOST_ARCHEXCLUDE=""
	[ -z "$ARCH" ] && ARCH="$(uname -m)"
	printf "%s\n" $ARCH |grep -qE "^arm" && ARCH=armv7hnl
	printf "%s\n" $ARCH |grep -qE "i.86" && ARCH=i686

	# Exclude 32-bit compat packages on multiarch capable systems
	case $ARCH in
	znver1|x86_64)
		HOST_ARCHEXCLUDE='--exclude=*.i686'
		;;
	aarch64)
		HOST_ARCHEXCLUDE='--exclude=*.armv7hnl'
		;;
	esac

	# List of packages that needs to be installed inside lxc-container and local machines
	RPM_LIST="xorriso squashfs-tools bc imagemagick kpartx gdisk gptfdisk git dosfstools qemu-x86_64-static dnf-plugins-core unix2dos"
	if [ $(rpm -qa $RPM_LIST | wc -l) = "$(wc -w <<< ${RPM_LIST})" ]; then
		printf "%s\n" "->All the correct system files are installed "
		if [ ! -d "$WORKDIR/dracut" ]; then
			find "$WORKDIR"
			touch "$WORKDIR/.new"
		else
			printf "%s\n" "-> Your build lists have been retained" # Files already copied
		fi
	else
		printf "%s\n" "-> Installing rpm files inside system environment"
		dnf install -y --setopt=install_weak_deps=False --releasever=${TREE} --forcearch="${ARCH}" "${HOST_ARCHEXCLUDE}" ${RPM_LIST}
		dnf upgrade --refresh --assumeyes --forcearch="${ARCH}" "${HOST_ARCHEXCLUDE}" --releasever=${TREE}
  
		printf "%s\n" '-> Updating rpms files inside system environment'
		printf "%s\n" '-> Updating dnf.conf to cache packages for rebuild'
		printf "%s\n" 'keepcache=True' >> /etc/dnf/dnf.conf
		if [ ! -d "$WORKDIR/dracut" ]; then
			find "$WORKDIR"
			touch "$WORKDIR/.new"
		else
			printf "%s\n" "-> Your build lists have been retained" # Files already copied
		fi
	fi
}

# Usage: createChroot packages.lst /target/dir
# Creates a chroot environment with all packages in the packages.lst
# file and their dependencies in /target/dir

# Start rpm packages installation
# If we are IN_ABF=1 then build a standard iso
# If we are IN_ABF=1 and DEBUG is set then we are running the ABF mode locally.
# In this mode the NOCLEAN flag is allowed.
# If set this will build a standard iso initially once built subsequent runs
# with NOCLEAN set will update the chroot with any changed file entries.
# If we are IN_ABF=0 then
# If the NOCLEAN flag and the .noclean file does not exist and there is no /lib/modules in the chroot
# then an iso will be built using the standard files
# plus the contents of the two user files my.add and my.rmv.

# Once built subsequent runs with NOCLEAN set will update the chroot with
# any changed entries in the user files only.
# if --rebuild is set then rebuild the chroot using the standard and user file lists.
# This uses the preserved rpm cache to speed up the rebuild.
# Files that were added to the user files will be downloaded.
createChroot() {
	# Make sure /proc, /sys and friends can be mounted so %post scripts can use them
	mkdir -p "$CHROOTNAME/proc" "$CHROOTNAME/sys" "$CHROOTNAME/dev" "$CHROOTNAME/dev/pts"

	if [ -n "$REBUILD" ]; then
		ANYRPMS=$(find "$CHROOTNAME/var/cache/dnf/" -name "basesystem-minimal*.rpm"  -type f  -printf %f)
		if [ -z "$ANYRPMS" ]; then
			printf "%s\n" "-> You must run with --noclean before you use --rebuild"
			errorCatch
		fi
	else
		printf "%s\n" "-> Rebuilding."
	fi

	for f in dev dev/pts proc sys; do
	    mount --bind -o ro "/$f" "$CHROOTNAME/$f"
	done

	if [ "$ABF" = '1' ]; then
		# Just build a chroot if DEBUG is not we will have
		# been thrown out long before we have got here.
		printf "%s\n" "Creating chroot"
		mkOmSpin
	elif [ ! -f "$CHROOTNAME/.noclean" ]; then
		printf "%s\n" "Creating an user chroot"
		mkUserSpin
		touch "$CHROOTNAME/.noclean"
	fi

	if [ "$ABF" = '0' ]; then
		if [ -n "$REBUILD" ]; then
			printf  "%s\n" "-> Rebuilding."
			mkUserSpin "$FILELISTS"
		elif [ -n "$AUTO_UPDATE" ]; then
			/usr/bin/dnf --refresh distro-sync --installroot "$CHROOTNAME"
		elif [ -n "$NOCLEAN" ] && [ -f "$CHROOTNAME"/.noclean ]; then
			printf "%s\n" "-> Updating user spin"
			updateUserSpin
		else
			mkUserSpin
		fi
	fi

	# Did it return 0k
	if [ $? != 0 ] && [ ${TREE,,} != "cooker" ]; then
		printf "%s\n" "-> Can not install packages from $FILELISTS"
		errorCatch
	fi

	# Check CHROOT
	if [ ! -d  "$CHROOTNAME"/lib/modules ]; then
		printf "%s\n" "-> Broken chroot installation." "Exiting"
		/bin/rm -f $CHROOTNAME/.noclean
		errorCatch
	fi

	# There's a problem here if you have something like desktop and desktop-clang kernels as module detection fails if
	# the boot kernel type is defined as desktop. You have to be careful about what you put in --boot-kernel-type
	# Somehow this has to be fixed perhaps with a lookup or translation table.
	# Export installed and boot kernel
	cd "$CHROOTNAME"/lib/modules > /dev/null 2>&1
	BOOT_KERNEL_ISO="$(ls -d --sort=time [0-9]* | grep "$BOOT_KERNEL_TYPE" | head -n1 | sed -e 's,/$,,')"
	export BOOT_KERNEL_ISO
	if [ -n "$BOOT_KERNEL_TYPE" ]; then
		printf "%s\n" "$BOOT_KERNEL_TYPE" > "$CHROOTNAME/boot_kernel"
		KERNEL_ISO=$(ls -d --sort=time [0-9]* | grep -v "$BOOT_KERNEL_TYPE" | head -n1 | sed -e 's,/$,,')
	else
		KERNEL_ISO=$(ls -d --sort=time [0-9]* |head -n1 | sed -e 's,/$,,')
	fi
	export KERNEL_ISO
	cd - > /dev/null 2>&1
	# remove rpm db files which may not match the target chroot environment
	chroot "$CHROOTNAME" rm -f /var/lib/rpm/__db.*
}

# Usage: mkOmSpin [main install file path} i.e. [path]/omdv-kde4.lst.
# Returns a variable "$INSTALL_LIST" containing all rpms
# to be installed
mkOmSpin() {
	getIncFiles "$FILELISTS" ADDRPMINC
	printf "%s" "$ADDRPMINC" > "$WORKDIR/inclist"
	printf "%s\n" "-> Creating OpenMandriva spin from" "$FILELISTS" " " "   Which includes"
	printf "%s" "$ADDRPMINC" | grep -v "$FILELISTS"
	createPkgList "$ADDRPMINC" INSTALL_LIST
	mkUpdateChroot "$INSTALL_LIST"
}

## (crazy) move to arry's for the .lst stuff that is.
# Usage: getIncFiles [filename] xyz.* $"[name of variable to return]
# Returns a sorted list of include files
# Function: Gets all the include lines for the specified package file
# The full path to the package list must be supplied

getIncFiles() {
	# Define some local variables
	local __infile="$1"   # The main build file
	local __incflist="$2" # Carries returned variable
	local __addrpminc # It's critical that this is local otherwise the content of previous runs corrupts the current list.

	# wow, cool a nested function...
	getEntrys() {
		# Recursively fetch included files
		while read -r r; do
			[ -z "$r" ] && continue
			# $'\n' nothing else works just don't go there.
			__addrpminc+=$'\n'"$WORKDIR/iso-pkg-lists-$TREE/$r"
			getEntrys "$WORKDIR/iso-pkg-lists-$TREE/$r"
			# Avoid sub-shells make sure commented out includes are removed.
		done < <(cat "$1" | grep '^[A-Za-z0-9 \t]*%include' | awk -F'.///' '{print $2}' |  sed '/ #/d ; /^\s$/d ; /^$/d') > /dev/null 2>&1
		# The above may appear as a useless use of cat but it's removal results in a permission denied error (even as sudo)
		# this is presumably because the contents of $1 is actually a path to a file.
	}

	getEntrys "$1"
	# Add the primary file to the list
	__addrpminc+=$'\n'"$__infile"
	# Sort and remove dupes.
	__addrpminc=$(printf "%s" "$__addrpminc" | sort -u | uniq -u)
	# Export
	eval $__incflist="'$__addrpminc'"
}

# Usage: createPkgList  "$VAR" VARNAME
# Function: Creates lists of packages from package lists
# VAR: A variable containing a list of package lists
# VARNAME: A variable name to identify the returned list of packages.
# Intent: Can be used to generate named variables
# containing packages to install or remove.

# NOTE: This routine requires 'lastpipe' so that
# subshells do not dump their data.
# This requires that job control be disabled.

# real really FIXME! - crazy -
createPkgList() {
	set +m
	shopt -s lastpipe
	# Define a local variable to hold user VAR
	local __pkglist=$2 # Carries returned variable name
	# other locals not needed outside routine
	local __pkgs # The list of packages
	local __pkglst # The current package list
	while read -r __pkglst; do
		__pkgs+=$'\n'$(cat "$__pkglst") >/dev/null 2>1
	done < <(printf '%s\n' "$1") >/dev/null 2>&1
	# sanitise regex compliments of TPG
	__pkgs=$(printf '%s\n' "$__pkgs" | grep -v '%include' | sed -e 's,		, ,g;s,  *, ,g;s,^ ,,;s, $,,;s,#.*,,' | sed -n '/^$/!p' | sed 's/ $//')
	# The above was getting comments that occured after the package name i.e. vim-minimal #mini-iso9660. but was leaving a trailing space which confused parallel and it failed the install

	eval $__pkglist="'$__pkgs'"
	if [ -n "$DEBUG" ]; then
		printf  "%s\n" "-> This is the $2 package list"
		printf "%s\n" "$__pkgs"
		printf "%s" "$__pkgs" >"$COMMITDIR/$2.list"
	fi

	shopt -u lastpipe
	set -m
	printf "%s\n" "$SEQNUM" >"$COMMITDIR/sessrec/.seqnum"
	> /dev/null
}

# Usage: mkUpdateChroot [Install variable] [remove variable]
# Function:	  If the --noclean option is set and a full chroot has been built
#			   (presence of .noclean in the chroot directory) then this function will be
#			   called when a change is detected in the users iso-build-lists.
#			   If the rebuild flag is set the entire chroot will be rebuilt using
#			   the main and user created configurations lists.
#			   It will first add any specified packages to the current chroot
#			   and then remove the specified packages using the auto-orphan option
#			   if the variable is not empty.
#			   As a minimum the INSTALL_LIST must exist in the environment.
#			   The optional REMOVE_LIST  can also be supplied.
#			   These variables must contain lists of newline
#			   separated package names for installation or removal.
#			   The variable names are flexible but their content and order on the commandline
#			   are mandatory.
mkUpdateChroot() {
	printf "%s\n\n" "-> Updating chroot"
	 __install_list="$1"
	 __remove_list="$2"

	if [ "$ABF" = '0' ]; then
		# Sometimes the order of add and remove are critical for example if a package needs to be replaced with the same package
		# the package needs to be removed first thus the remove list needs to be run first. If the same package exists in both
		# add and remove lists then remove list needs to be run first but there no point in running a remove list first if there's no rpms to remove because
		# they haven't been installed yet. So removing rpms only needs to be invoked first if the NOCLEAN flag is set indicating a built chroot. The problem
		# is that the replacepkgs flag does not install if the package has not been installed that are already there so the package has to be removed first
		# otherwise parts of the install list will fail. A replace list could be provided. A simple fix for the moment turn both operations into functions
		# and call then through logic which determines whether --noclean has been invoked.
		if [ -n "$NOCLEAN" ] && [ -f "$CHROOTNAME/.noclean" ]; then
			MyRmv
			MyAdd
		else
			MyAdd
			MyRmv
		fi
	elif [ "$ABF" = '1' ]; then
		printf "%s\n" "-> Installing packages at ABF" " "
		if [ -n "$__install_list" ]; then # Dont do it with an empty list
			/usr/bin/dnf install -y --refresh --releasever=${TREE} --forcearch="${EXTARCH}" ${ARCHEXCLUDE} --installroot "$CHROOTNAME" ${__install_list} | tee "$WORKDIR/dnfopt.log"
			printf "%s\n" "$__install_list" >"$WORKDIR/RPMLIST.txt"
		fi
	fi
}

# The MyAdd and MyRmv functions can't take full advantage of parallel until a full rpm dep list is produced
# which means using a solvedb setup. We can however make use of it's fail utility.. Add some logging too.
# Usage: MyAdd
MyAdd() {
	if [ -n "$DEBUG" ]; then
		printf "%s\n" "MyAdd"
	fi
	if [ -n "$__install_list" ]; then
		printf "%s\n" "-> Installing user package selection" " "
		/usr/bin/dnf install -y --refresh --releasever=${TREE} --forcearch="${EXTARCH}" ${ARCHEXCLUDE} --installroot "$CHROOTNAME" ${__install_list} | tee "$WORKDIR/dnfopt.log"
		printf "%s\n" "$__install_list" >"$WORKDIR/RPMLIST.txt"
	fi
}

# Usage: MyRmv
MyRmv() {
	if [ -n "$DEBUG" ]; then
		printf "%s\n" "MyRmv"
	fi
	if [ -n "$__remove_list" ]; then
# Before we do anything here we have to consider that the user may have
# added packages to the remove list which have been breaking the build.
# Any duplicates that appear in both lists removed from BOTH lists
# This works even if the packages are not installed
		printf "%s" "-> Removing user specified rpms and orphans" " "
		/usr/bin/dnf autoremove -y --installroot "$CHROOTNAME" "$__remove_list"
	else
		printf "%s\n" " " "-> No rpms need to be removed"
	fi
}

# mkUserSpin [main install file path} i.e. [path]/omdv-kde4.lst
# Sets two variables
# $INSTALL_LIST = All list files to be installed
# $REMOVE_LIST = All list files to be removed
# This function includes all the user adds and removes.
mkUserSpin() {
	if [ -n "$DEBUG" ]; then
		printf "%s\n" "mkUserSpin"
	fi
	printf "%s\n" "-> Making a user spin"
	printf "%s\n" "Change Flag = $CHGFLAG"
	printf "%s\n" "$FILELISTS"
	getIncFiles "$FILELISTS" ADDRPMINC
	# Combine the main and the users files"
	ALLRPMINC=$(echo "$ADDRPMINC"$'\n'"$UADDRPMINC" | sort -u)
	# Now for the remove list
	getIncFiles "$WORKDIR/iso-pkg-lists-$TREE/my.rmv" RMRPMINC
	printf "%s\n" "-> Removing the common include lines for the remove package includes"

	#Give some information
	printf "%s\n" "-> Creating $WHO's OpenMandriva spin from $FILELISTS" "  Which includes " "$ALLRPMINC"
	printf "%s\n" "-> Removing from $WHO's OpenMandriva spin from $FILELISTS" "  Which removes " "$RMRPMINC"
	# Create the package lists
	createPkgList "$ALLRPMINC" INSTALL_LIST
	createPkgList "$RMRPMINC" REMOVE_LIST
	INSTALL_LIST=$(comm -13 <(printf '%s\n' "$REMOVE_LIST" | sort -u) <(printf '%s\n' "$INSTALL_LIST" | sort -u))
	# Remove any files from the install list which in the remove list
	printf "%s\n" "This is the install list" " " "$INSTALL_LIST" " " "End of install list"
	mkUpdateChroot "$INSTALL_LIST" "$REMOVE_LIST"
}

# updateUserSpin [main install file path] i.e. path/omdv-kde4.lst
# Sets two variables
# INSTALL_LIST = All list files to be installed
# REMOVE_LIST = All list files to be removed
# This function only updates using the user my.add and my.rmv files.
# It is used to add user updates after the main chroot
# has been created with mkUserSpin.
updateUserSpin() {
	[ -n "$DEBUG" ] && printf '%s\n' "updateUserSpin"
	printf "%s\n" "-> Updating user spin"
	# re-assign just for consistancy
	ALLRPMINC="$UADDRPMINC"
	getIncFiles "$WORKDIR/iso-pkg-lists-$TREE/my.rmv" RMRPMINC
	printf "%s\n" " " "-> This is the user include list"
	printf "%s\n" "$ALLRPMINC" "-> End of user include list" " "
	printf "%s\n" " " "-> This is the remove include list"
	printf "%s\n" "$RMRPMINC" "-> End of remove list" " "
	printf "%s\n" -> "Remove any duplicate includes"
	# This should signal an error to the user
	RMRPMINC_TMP=$(comm -12 <(printf '%s\n' "$ALLRPMINC" | sort ) <(printf '%s\n' "$RMRPMINC" | sort))
	[ -n "$RMRPMINC_TMP" ] && printf "%s\n" -> "Error: ->> The are identical include files in the add and remove lists" "->> You probably don't want this"
	printf "%s\n" "-> Creating the package lists"
	createPkgList "$ALLRPMINC" INSTALL_LIST
	createPkgList "$RMRPMINC" REMOVE_LIST
	# Remove any packages that occur in both lists
	INSTALL_LIST=$(comm -13 <(printf '%s\n' "$REMOVE_LIST" | sort -u) <(printf '%s\n' "$INSTALL_LIST" | sort -u)) > /dev/null 2>&1
	printf "%s\n" "-> This is the install package list" "$INSTALL_LIST" "->End of install pkg list" " "
	printf "%s\n" "-> This is the remove package list" "$REMOVE_LIST" "End of remove pkg list"

	mkUpdateChroot "$INSTALL_LIST" "$REMOVE_LIST"
}

createInitrd() {
	# Check if dracut is installed
	if [ ! -f "$CHROOTNAME/sbin/dracut" ]; then
		printf "%s\n" "-> dracut is not installed inside chroot." "Exiting."
		errorCatch
	fi

	# Build initrd for syslinux
	printf "%s\n" "-> Building liveinitrd-${BOOT_KERNEL_ISO} for ISO boot"
	if [ ! -f "$WORKDIR/dracut/dracut.conf.d/99-dracut-isobuild.conf" ]; then
		printf "%s\n" "-> Missing $WORKDIR/dracut/dracut.conf.d/99-dracut-isobuild.conf." "Exiting."
		errorCatch
	fi

	cp -f "$WORKDIR"/dracut/dracut.conf.d/99-dracut-isobuild.conf "$CHROOTNAME"/etc/dracut.conf.d/99-dracut-isobuild.conf

	if [ ! -d "$CHROOTNAME"/usr/lib/dracut/modules.d/90liveiso ]; then
		printf "%s\n" "-> Dracut is missing 90liveiso module. Installing it."

		if [ ! -d "$WORKDIR"/dracut/90liveiso ]; then
			printf "%s\n" "-> Cant find 90liveiso dracut module in $WORKDIR/dracut. Exiting." " "
			errorCatch
		fi

		cp -a -f "$WORKDIR"/dracut/90liveiso "$CHROOTNAME"/usr/lib/dracut/modules.d/
		chmod 0755 "$CHROOTNAME"/usr/lib/dracut/modules.d/90liveiso
		chmod 0755 "$CHROOTNAME"/usr/lib/dracut/modules.d/90liveiso/*.sh
	fi

	# Fugly hack to get /dev/disk/by-label
	sed -i -e '/KERNEL!="sr\*\", IMPORT{builtin}="blkid"/s/sr/none/g' -e '/TEST=="whole_disk", GOTO="persistent_storage_end"/s/TEST/# TEST/g' "$CHROOTNAME"/lib/udev/rules.d/60-persistent-storage.rules
	if [ $? != 0 ]; then
		printf "%s\n" "-> Failed with editing /lib/udev/rules.d/60-persistent-storage.rules file. Exiting."
		errorCatch
	fi

	if [ -f "$CHROOTNAME"/boot/liveinitrd.img ]; then
		rm -rf "$CHROOTNAME"/boot/liveinitrd.img
	fi

	# Set default plymouth theme
	if [ -x "$CHROOTNAME"/usr/sbin/plymouth-set-default-theme ]; then
		chroot "$CHROOTNAME" /usr/sbin/plymouth-set-default-theme OpenMandriva
	fi

	# Building liveinitrd
	chroot "$CHROOTNAME" /sbin/dracut -N -f --no-early-microcode --nofscks /boot/liveinitrd.img --conf /etc/dracut.conf.d/99-dracut-isobuild.conf "$BOOT_KERNEL_ISO"
	if [ -n "$BOOT_KERNEL_TYPE" ]; then
		chroot "$CHROOTNAME" /sbin/dracut -N -f --no-early-microcode --nofscks /boot/liveinitrd1.img --conf /etc/dracut.conf.d/99-dracut-isobuild.conf "$KERNEL_ISO"
	fi
	if [ ! -f "$CHROOTNAME"/boot/liveinitrd.img ]; then
		printf "%s\n" "-> File $CHROOTNAME/boot/liveinitrd.img does not exist. Exiting."
		errorCatch
	fi

	printf "%s\n" "-> Building initrd-$KERNEL_ISO inside chroot"
	# Remove old initrd
	rm -rf "$CHROOTNAME/boot/initrd-$KERNEL_ISO.img"
	rm -rf "$CHROOTNAME"/boot/initrd0.img

	# Move configs to /usr/share/dracut/ for diagnostics on live images. Probably should be removed by Calamares post-install scripts
	mv  "$CHROOTNAME"/etc/dracut.conf.d/99-dracut-isobuild.conf  "$CHROOTNAME"/usr/share/dracut/
	mv  "$CHROOTNAME"/usr/lib/dracut/modules.d/90liveiso "$CHROOTNAME"/usr/share/dracut/

	# Building initrd
	chroot "$CHROOTNAME" /sbin/dracut -N -f "/boot/initrd-$KERNEL_ISO.img" "$KERNEL_ISO"
	if [ $? != 0 ]; then
		printf "%s\n" "-> Failed creating initrd. Exiting."
		errorCatch
	fi

	# Build the boot kernel initrd in case the user wants it kept
	if [ -n "$BOOT_KERNEL_TYPE" ]; then
		# Building boot kernel initrd
		printf "%s\n" "-> Building initrd-$BOOT_KERNEL_ISO inside chroot"
		chroot "$CHROOTNAME" /sbin/dracut -N -f "/boot/initrd-$BOOT_KERNEL_ISO.img" "$BOOT_KERNEL_ISO"
		if [ $? != 0 ]; then
			printf "%s\n" "-> Failed creating boot kernel initrd. Exiting."
			errorCatch
		fi
	fi

	ln -sf "/boot/initrd-$KERNEL_ISO.img" "$CHROOTNAME/boot/initrd0.img"
}

# Usage: createMemDIsk <target_directory/image_name>.img <grub_support_files_directory> <grub2 efi executable>
# Creates a fat formatted file ifilesystem image which will boot an UEFI system.
createMemDisk() {
	if [ "$EXTARCH" = 'x86_64' ] || [ "$EXTARCH" = 'znver1' ]; then
		ARCHFMT=x86_64-efi
		ARCHPFX=X64
	elif [ "$EXTARCH" = 'aarch64' ]; then
		ARCHFMT=arm64-efi
		ARCHPFX=AA64
	elif printf "%s\n" $EXTARCH |grep -qE '^(i.86|znver1_32|athlon)'; then
		ARCHFMT=i386-efi
		ARCHPFX=IA32
	fi

	# Create the ISO directory
	mkdir -m 0755 -p "$ISOROOTNAME"/EFI/BOOT
	# and the grub diectory
	mkdir -m 0755 -p "$ISOROOTNAME"/boot/grub

	ARCHLIB="/usr/lib/grub/$ARCHFMT"
	EFINAME=BOOT"$ARCHPFX.efi"
	printf "%s\n" "-> Setting up UEFI memdisk image."
	GRB2FLS="$ISOROOTNAME/EFI/BOOT"
	# Create memdisk directory
	if [ -e "$WORKDIR/boot/grub" ]; then
		/bin/rm -R "$WORKDIR/boot/grub"
		mkdir -p "$WORKDIR/boot/grub"
	else
		mkdir -p "$WORKDIR/boot/grub"
	fi
	MEMDISKDIR="$WORKDIR/boot/grub"

	# Copy the grub config file to the chroot dir for UEFI support
	# Also set the uuid
	cp -f "$WORKDIR/grub2/start_cfg" "$MEMDISKDIR/grub.cfg"
	sed -i -e "s/%GRUB_UUID%/${GRUB_UUID}/g" "$MEMDISKDIR/grub.cfg"

	# Ensure the old image is removed
	if [ -e "$CHROOTNAME/memdisk_img" ]; then
		rm -f "$CHROOTNAME/memdisk_img"
	fi

	# Create a memdisk img called memdisk_img
	cd "$WORKDIR" || exit
	tar cvf "$CHROOTNAME/memdisk_img" boot

	# Make the image locally rather than rely on the grub2-rpm this allows more control as well as different images for IA32 if required
	# To do this cleanly it's easiest to move the ISO directory containing the config files to the chroot, build and then move it back again
	mv -f "$ISOROOTNAME" "$CHROOTNAME"

	# Job done just remember to move it back again
	chroot "$CHROOTNAME"  /usr/bin/grub2-mkimage -O "$ARCHFMT" -d "$ARCHLIB" -m memdisk_img -o "/ISO/EFI/BOOT/$EFINAME" -p '(memdisk)/boot/grub' \
	iso9660 normal memdisk tar linux part_msdos part_gpt part_apple configfile help loadenv ls reboot chain multiboot fat udf \
	ext2 btrfs ntfs reiserfs xfs lvm ata cat test echo multiboot multiboot2 all_video efifwsetup efinet font gcry_rijndael gcry_rsa gcry_serpent \
	gcry_sha256 gcry_twofish gcry_whirlpool gfxmenu gfxterm gfxterm_menu gfxterm_background gzio halt hfsplus jpeg mdraid09 mdraid1x minicmd part_apple \
	part_msdos part_gpt part_bsd password_pbkdf2 png probe \
	search search_fs_uuid search_fs_file search_label sleep tftp video xfs loopback regexp

	if [ $? != 0 ]; then
		printf "%s\n" "-> Failed to create grub2 EFI image." "Exiting."
		errorCatch
	fi
	# Move back the ISO filesystem after building the EFI image.
	mv -f "$CHROOTNAME/ISO/" "$ISOROOTNAME"

	# Ensure the ISO image is clear
	if [ -e "$CHROOTNAME/memdisk_img" ]; then
		rm -f "$CHROOTNAME/memdisk_img"
	fi
}

# Usage: createEFI $EXTARCH $ISOCHROOTNAME
# Creates a fat formatted file in filesystem image which will boot an UEFI system.
# PLEASE NOTE THAT THE ISO DIRECTORY IS TEMPORARILY MOVED TO THE CHROOT DIRECTORY FOR THE PURPOSE OF GENERATING THE GRUB IMAGE.
createUEFI() {
	if [ "$EXTARCH" = 'x86_64' ] || [ "$EXTARCH" = 'znver1' ]; then
		ARCHFMT=x86_64-efi
		ARCHPFX=X64
	elif [ "$EXTARCH" = 'aarch64' ]; then
		ARCHFMT=arm64-efi
		ARCHPFX=AA64
	elif printf "%s\n" $EXTARCH |grep -qE '^(i.86|znver1_32|athlon)'; then
		ARCHFMT=i386-efi
		ARCHPFX=IA32
	fi
	ARCHLIB=/usr/lib/grub/"$ARCHFMT"
	EFINAME=BOOT"$ARCHPFX".efi
	printf "%s\n" "-> Setting up UEFI partiton and image."

	IMGNME="$ISOROOTNAME/boot/grub/$EFINAME"
	GRB2FLS="$ISOROOTNAME"/EFI/BOOT

	printf "%s\n" "-> Building GRUB's EFI image."
	if [ -e "$IMGNME" ]; then
		rm -rf "$IMGNME"
	fi
	FILESIZE=$(du -s --block-size=512 "$ISOROOTNAME"/EFI | awk '{print $1}')
	EFIFILESIZE=$(( FILESIZE * 2 ))
	PARTTABLESIZE=$(( (2*17408)/512 ))
	EFIDISKSIZE=$((  $EFIFILESIZE + $PARTTABLESIZE + 2 ))

	# Create the image.
	printf "%s\n" "-> Creating EFI image with size $EFIDISKSIZE"

	# mkfs.vfat can create the image and filesystem directly
	mkfs.vfat -n "OPENMDVASS" -C -F 16 -s 1 -S 512 -M 0xFF -i 22222222 "$IMGNME" "$EFIDISKSIZE"
	# Loopback mount the image
	# IMPORTANT NOTE: In OMDV 4.x.x series kernels the loop driver is compiled as a module
	# This causes problems when building in an ABF iso container.
	# When the container is started if the the main kernel has not started the loop driver then
	# no loop devices will be created in the docker isobuilder instance so the module must be loaded before
	# running losetup this is achieved by running "losetup -f" with no arguments.
	# A further side effect is that if the module is loaded from inside docker when an image is mounted
	# on the docker loop device it is also mounted on ALL the available device names in the host OS thus
	# making the loop devices unavailable to the main kernel though additional devices may be used in the docker instance.
	# Yet another side effect is that the host OS automounts all the loop devices which then makes it impossible
	# to unmount them from inside the container. This problem can be overcome by adding the following rule to the docker-80.rules file
	# SUBSYSTEM=="block", DEVPATH=="/devices/virtual/block/loop*", ENV{ID_FS_UUID}="2222-2222", ENV{UDISKS_PRESENTATION_HIDE}="1", ENV{UDISKS_IGNORE}="1"
	# The indentifiers in the files system image are used to ensure that the rule is unique to this script

	losetup -f  > /dev/null 2>&1
	# Make sure loop device is loaded
	sleep 2
	losetup -f "$IMGNME"
	sleep 1
	if [ $? != 0 ]; then
		printf "%s\n" "-> Failed to mount loopback image." "Exiting."
		errorCatch
	fi
	sleep 1

mount -t vfat "$IMGNME" /mnt
	if [ $? != 0 ]; then
		printf "%s\n" "-> Failed to mount UEFI image." "Exiting."
		errorCatch
	fi

	# Copy the Grub2 files to the EFI image
	mkdir -p /mnt/EFI/BOOT
	cp -R "$GRB2FLS"/"$EFINAME" /mnt/EFI/BOOT/"$EFINAME"

	# Create a startup.nsh file to feed to the VirtualBox EFI shell
	cat  >/mnt/EFI/BOOT/startup.nsh <<EOF
fs1:
cd EFI/BOOT
BOOTX64.EFI
EOF
	unix2dos /mnt/EFI/BOOT/startup.nsh

	# Unmout the filesystem with EFI image
	umount /mnt
	# Be sure to delete the loop device
	losetup -D
	# Make sure that the image is copied to the ISOROOT
	cp -f  "$IMGNME" "$ISOROOTNAME"
	# Clean up
	kpartx -d "$IMGNME"
	# Remove the EFI directory
	rm -R "$ISOROOTNAME/EFI"
	XORRISO_OPTIONS2=" --efi-boot $EFINAME -append_partition 2 0xef $IMGNME"
}

# Usage: setupGrub2 (chroot directory (~/BASE) , iso directory (~/ISO), configdir (~/omdv-build-iso-<arch>)
# Sets up grub2 to boot /target/dir
setupGrub2() {
	if [ ! -e "$CHROOTNAME"/usr/bin/grub2-mkimage ]; then
		printf "%s\n" "-> Missing grub2-mkimage in installation."
		errorCatch
	fi

	# BIOS Boot and theme support
	# NOTE Themes are used by the EFI boot as well.
	# Copy grub config files to the ISO build directory
	# and set the UUID's
	pushd "$WORKDIR"/grub2-menus
	./grub-menu
	popd
	cp -f "$WORKDIR"/grub2-menus/grub2-bios.cfg "$ISOROOTNAME"/boot/grub/grub.cfg
	if [ -n "$DEFAULTLANG" ]; then
		sed -i -e "0,/\(set bootlang=\).*/s//\1'$DEFAULTLANG'/" "$ISOROOTNAME"/boot/grub/grub.cfg
	fi
	if [ -n "$DEFAULTKBD" ]; then
		sed -i -e "0,/\(set bootkeymap=\).*/s//\1'$DEFAULTKBD'/" "$ISOROOTNAME"/boot/grub/grub.cfg
	fi
	sed -i -e "s/%GRUB_UUID%/${GRUB_UUID}/g" "$ISOROOTNAME"/boot/grub/grub.cfg
	cp -f "$WORKDIR"/grub2/start_cfg "$ISOROOTNAME"/boot/grub/start_cfg
	printf "%s\n" "-> Setting GRUB_UUID to ${GRUB_UUID}"
	sed -i -e "s/%GRUB_UUID%/${GRUB_UUID}/g" "$ISOROOTNAME"/boot/grub/start_cfg
	if [ $? != 0 ]; then
		printf "%s\n" "-> Failed to set up GRUB_UUID."
		errorCatch
	fi

	# Add the themes, locales and fonts to the ISO build firectory
	if [ "${TYPE}" != "minimal" ]; then
		mkdir -p "$ISOROOTNAME"/boot/grub "$ISOROOTNAME"/boot/grub/themes "$ISOROOTNAME"/boot/grub/locale "$ISOROOTNAME"/boot/grub/fonts
		cp -a -f "$CHROOTNAME"/boot/grub2/themes "$ISOROOTNAME"/boot/grub/
		cp -a -f "$CHROOTNAME"/usr/share/grub/*.pf2 "$ISOROOTNAME"/boot/grub/fonts/
		sed -i -e "s/title-text.*/title-text: \"Welcome to OpenMandriva Lx $VERSION ${EXTARCH} ${TYPE} BUILD ID: ${BUILD_ID}\"/g" "$ISOROOTNAME"/boot/grub/themes/OpenMandriva/theme.txt > /dev/null 2>&1
		if [ $? != 0 ]; then
			printf "%s\n" "-> WARNING Failed to update Grub2 theme." "Please add a grub theme to my.add if needed."
			# errorCatch
		fi
	fi

	printf "%s\n" "-> Building Grub2 El-Torito image and an embedded image."

	GRUB_LIB=/usr/lib/grub/i386-pc
	GRUB_IMG=$(mktemp)

	# Copy memtest
	cp -rfT "$WORKDIR/extraconfig/memtest" "$ISOROOTNAME/boot/grub/memtest"
	chmod +x "$ISOROOTNAME/boot/grub/memtest"
	# To use an embedded image with our grub2 we need to make the modules available in the /boot/grub directory of the iso.
	# The modules can't be carried in the payload of the embedded image as it's size is limited to 32kb.
	# So we copy the i386-pc modules to the isobuild directory

	mkdir -p "$ISOROOTNAME/boot/grub/i386-pc"
	cp -rf "$CHROOTNAME/usr/lib/grub/i386-pc" "$ISOROOTNAME/boot/grub/"

	# Build the grub images in the chroot rather that in t"$CHROOTNAME"he host OS this avoids any issues with different versions of grub in the host OS especially when using local mode.
	# this means cooker isos can be built on a local machine running a different version of OpenMandriva
	# It requires that all the files needed to build the image must be within the chroot directory when the chroot command is invoked.
	# Also we cannot write outside of the chroot so the images generated will remain in the chroot directory and will need to be removed before the squashfs is built
	# these will be in /tmp and they are only small so leave them for the time being.
	# If the entire ~/ISO director is copied to the chroot we do do have to worry too much about hacking the existing script to work
	# with new paths we can simple add the $CHROOTNAME to the $ISOCHROOTNAME to get get the new path.
	# So the quickest and easiest method is to mv the $ISOROOTNAME this avoids having two copies and is simple to understand
	# First thoughmake sure we actually build new images
	if [ -e "$ISOROOTNAME/boot/grub/grub-eltorito.img" -o -e "$ISOROOTNAME/boot/grub/grub2-embed_img" ]; then
		rm -rf "$ISOROOTNAME/boot/grub/{grub-eltorito,grub-embedded}.img"
	fi

	mv -f "$ISOROOTNAME" "$CHROOTNAME"
	# Job done just remember to move it back again
	# Make the image
	chroot "$CHROOTNAME" /usr/bin/grub2-mkimage -d "$GRUB_LIB" -O i386-pc -o "$GRUB_IMG" -p /boot/grub -c /ISO/boot/grub/start_cfg  iso9660 biosdisk test
	# Move the ISO director back to the working directory
	mv -f "$CHROOTNAME/ISO/" "$WORKDIR"
	# Create bootable hard disk image
	cat "$CHROOTNAME/$GRUB_LIB/boot.img" "$CHROOTNAME/$GRUB_IMG" > "$ISOROOTNAME/boot/grub/grub2-embed_img"
	if [ $? != 0 ]; then
		printf "%s\n" "-> Failed to create Grub2 El-Torito image." "Exiting."
		errorCatch
	fi
	# Create bootable cdimage
	cat "$CHROOTNAME/$GRUB_LIB/cdboot.img" "$CHROOTNAME/$GRUB_IMG" > "$ISOROOTNAME/boot/grub/grub2-eltorito.img"
	if [ $? != 0 ]; then
		printf  "%s\n" "-> Failed to create Grub2 El-Torito image." "Exiting."
		errorCatch
	fi

	XORRISO_OPTIONS1=" -b boot/grub/grub2-eltorito.img -no-emul-boot -boot-info-table --embedded-boot $ISOROOTNAME/boot/grub/grub2-embed_img --protective-msdos-label"

	# Copy SuperGrub iso
	# disable for now
	#	cp -rfT $OURDIR/extraconfig/super_grub2_disk_i386_pc_2.04s1.iso "$ISOROOTNAME"/boot/grub/sgb.iso

	printf "%s\n" "-> End building Grub2 El-Torito image."
	printf "%s\n" "-> Installing liveinitrd for grub2"

	if [ -e "$CHROOTNAME/boot/vmlinuz-$BOOT_KERNEL_ISO" ] && [ -e "$CHROOTNAME/boot/liveinitrd.img" ]; then
		cp -H "$CHROOTNAME/boot/vmlinuz-$BOOT_KERNEL_ISO" "$ISOROOTNAME/boot/vmlinuz0"
		cp -H "$CHROOTNAME/boot/liveinitrd.img" "$ISOROOTNAME/boot/liveinitrd.img"
		sed -i "s/%KCC_TYPE%/with ${BOOT_KERNEL_ISO}/" "$ISOROOTNAME"/boot/grub/grub.cfg
		if [ -n "$BOOT_KERNEL_TYPE" ]; then
			cp -H "$CHROOTNAME/boot/vmlinuz-$KERNEL_ISO" "$ISOROOTNAME/boot/vmlinuz1"
			cp -H "$CHROOTNAME/boot/liveinitrd1.img" "$ISOROOTNAME/boot/liveinitrd1.img"
# If dual kernels are used set up the grub2 menu to show them. This needs extra work
			ALT_KERNEL=$(printf "%s\n" "$KERNEL_ISO" | awk -F "-" '{print $2 "-gcc"}') #Fix this to use shell substitution perhaps"
			sed -i "s/%BOOT_KCC_TYPE%/with ${ALT_KERNEL}/" "$ISOROOTNAME"/boot/grub/grub.cfg
		else
# Remove the uneeded menu entry
			sed -i '/linux1/,+4 d' "$ISOROOTNAME"/boot/grub/grub.cfg
		fi
	else
		printf "%s\n" "-> vmlinuz or liveinitrd does not exists. Exiting."
		errorCatch
	fi

	if [ ! -f "$ISOROOTNAME/boot/liveinitrd.img" ]; then
		printf "%s\n" "-> Missing /boot/liveinitrd.img. Exiting."
		errorCatch
	else
		rm -rf "$CHROOTNAME/boot/liveinitrd.img"
	fi

	XORRISO_OPTIONS="$XORRISO_OPTIONS1 $XORRISO_OPTIONS2"
	rm -rf "$GRUB_IMG"
}

setupISOenv() {
	# Set up default timezone
	printf "%s\n" "-> Setting systemd firstboot"

# set up system environment, default root password is omv
	sudo /bin/systemd-firstboot --root="$CHROOTNAME" \
		--locale="$DEFAULTLANG" \
		--keymap="$DEFAULTKBD" \
		--timezone="Europe/London" \
		--hostname="omv-$BUILD_ID" \
		--delete-root-password \
		--force

# (tpg) this is already done by systemd.triggers, but run it anyways just to be safe
	sudo /bin/systemd-tmpfiles --root="$CHROOTNAME" --remove ||:
	sudo /bin/systemd-sysusers --root="$CHROOTNAME" ||:

# Create /etc/minsysreqs
	printf "%s\n" "-> Creating /etc/minsysreqs"

	if [ "${TYPE,,}" = "minimal" ]; then
		printf "%s\n" "ram = 512" >> "$CHROOTNAME/etc/minsysreqs"
		printf "%s\n" "hdd = 5" >> "$CHROOTNAME/etc/minsysreqs"
	elif [ "$EXTARCH" = "x86_64" ] || [ "$EXTARCH" = "znver1" ]; then
		printf "%s\n" "ram = 1536" >> "$CHROOTNAME/etc/minsysreqs"
		printf "%s\n" "hdd = 10" >> "$CHROOTNAME/etc/minsysreqs"
	else
		printf "%s\n" "ram = 1024" >> "$CHROOTNAME/etc/minsysreqs"
		printf "%s\n" "hdd = 10" >> "$CHROOTNAME/etc/minsysreqs"
	fi

	# Count imagesize and put in in /etc/minsysreqs
	printf "%s\n" "imagesize = $(du -a -x -b -P "$CHROOTNAME" | tail -1 | awk '{print $1}')" >> "$CHROOTNAME"/etc/minsysreqs

	# Set up displaymanager
	if [ ${TYPE,,} != "minimal" ] && [ ! -z ${DISPLAYMANAGER,,} ]; then
		if [ ! -e "$CHROOTNAME/lib/systemd/system/${DISPLAYMANAGER,,}.service" ]; then
			printf "%s\n" "-> File ${DISPLAYMANAGER,,}.service does not exist. Exiting."
			errorCatch
		fi

		ln -sf "/lib/systemd/system/${DISPLAYMANAGER,,}.service" "$CHROOTNAME/etc/systemd/system/display-manager.service" 2> /dev/null || :

		# (crazy) probably remove that ?
		# Set reasonable defaults
		if  [ -e "$CHROOTNAME/etc/sysconfig/desktop" ]; then
			rm -rf "$CHROOTNAME"/etc/sysconfig/desktop
		fi
	fi

	# Add the VirtualBox folder sharing group
	chroot "$CHROOTNAME" /usr/sbin/groupadd -f vboxsf
	chroot "$CHROOTNAME" /usr/sbin/groupadd -f lpadmin

	# Set up live user
	live_user=live
	printf "%s\n" "-> Setting up user ${live_user}"
	chroot "$CHROOTNAME" /usr/sbin/adduser -m -G nopasswd,vboxsf,lpadmin ${live_user}

	# Clear user passwords
	for username in root $live_user; do
	    # Kill it as it prevents clearing passwords
	    [ -e "$CHROOTNAME"/etc/shadow.lock ] && rm -rf "$CHROOTNAME"/etc/shadow.lock
	    printf "%s\n" "-> Clearing $username password."
	    chroot "$CHROOTNAME" /usr/bin/passwd -d $username||errorCatch
	done

# (tpg) allow to ssh for live user with blank password
	if [ -d "$CHROOTNAME"/etc/ssh/sshd_config.d ]; then
	cat > "$CHROOTNAME"/etc/ssh/sshd_config.d/50-live-iso.conf << EOF
Match User $live_user
    PasswordAuthentication yes
    PermitEmptyPasswords yes

EOF
	fi

	chroot "$CHROOTNAME" /bin/mkdir -p /home/${live_user}
	chroot "$CHROOTNAME" /bin/cp -rfT /etc/skel /home/${live_user}/
	chroot "$CHROOTNAME" /bin/mkdir -p /home/${live_user}/Desktop
	cp -rfT "$WORKDIR"/extraconfig/etc/skel "$CHROOTNAME"/home/${live_user}/
	chroot "$CHROOTNAME" /bin/mkdir -p /home/${live_user}/.cache
	chroot "$CHROOTNAME" /bin/chown -R ${live_user}:${live_user} /home/${live_user}
	chroot "$CHROOTNAME" /bin/chown -R ${live_user}:${live_user} /home/${live_user}/Desktop
	chroot "$CHROOTNAME" /bin/chown -R ${live_user}:${live_user} /home/${live_user}/.cache
	chroot "$CHROOTNAME" /bin/chmod -R 0777 /home/${live_user}/.local
	# (tpg) support for AccountsService
	chroot "$CHROOTNAME" /bin/mkdir -p /var/lib/AccountsService/users
	chroot "$CHROOTNAME" /bin/mkdir -p /var/lib/AccountsService/icons
	cp -f "$WORKDIR"/data/account-user "$CHROOTNAME"/var/lib/AccountsService/users/${live_user}
	cp -f "$WORKDIR"/data/account-icon "$CHROOTNAME"/var/lib/AccountsService/icons/${live_user}
	/bin/sed -i -e "s/_NAME_/${live_user}/g" "$CHROOTNAME"/var/lib/AccountsService/users/${live_user}

	rm -rf "$CHROOTNAME"/home/${live_user}/.kde4

	if [ "${TYPE,,}" = "plasma" ] || [ "${TYPE,,}" = "plasma6" ] || [ "${TYPE,,}" = "plasma6x11" ] || [ "${TYPE,,}" = "plasma-wayland" ] || [ "${TYPE}" = "edu" ]; then
		# disable baloo in live session
		mkdir -p "$CHROOTNAME"/home/${live_user}/.config
		cat >"$CHROOTNAME"/home/${live_user}/.config/baloofilerc << EOF
[Basic Settings]
Indexing-Enabled=false

[General]
first run=false
EOF

		# we really need disable automouter , it still fires udisks2 for some partition types
		[ -f "$CHROOTNAME"/home/${live_user}/.config/kded_device_automounterrc ] && rm -rf "$CHROOTNAME"/home/${live_user}/.config/kded_device_automounterrc
		cat >"$CHROOTNAME"/home/${live_user}/.config/kded_device_automounterrc << EOF
[General]
AutomountEnabled=false
EOF

		# kscreenlocker
		# see: https://forum.openmandriva.org/t/omlx-4-0-pre-alpha-iso-plasma-development-builds/2128/48
		# to manipulate Timeout change value to disable replace Timeout= with -> Autolock=false
		[ -f "$CHROOTNAME"/home/${live_user}/.config/kscreenlockerrc ] && rm -rf "$CHROOTNAME"/home/${live_user}/.config/kscreenlockerrc
		cat >"$CHROOTNAME"/home/${live_user}/.config/kscreenlockerrc << EOF
[Daemon]
Timeout=30
EOF
	fi

	case "${TYPE}" in
	edu)
		SESSION="plasmax11"
		;;
	plasma6)
		SESSION="plasma"
		;;
	plasma6x11)
		SESSION="plasmax11"
		;;
	*)
		SESSION="${TYPE}"
		;;
	esac

	# Enable DM autologin
	if [ "${TYPE,,}" != "minimal" ]; then
		case ${DISPLAYMANAGER,,} in
		"sddm")
			sed -i -e "s/^Session=.*/Session=${SESSION,,}.desktop/g" -e "s/^User=.*/User=${live_user}/g" "$CHROOTNAME"/etc/sddm.conf
			;;
		"gdm")
			if grep -q AutomaticLoginEnable "$CHROOTNAME"/etc/X11/gdm/custom.conf; then
				sed -i -e "s/^AutomaticLoginEnable.*/AutomaticLoginEnable=True/g" -e "s/^AutomaticLogin.*/AutomaticLogin=${live_user}/g" "$CHROOTNAME"/etc/X11/gdm/custom.conf
			else
				sed -i -e "/^\[daemon\]/aAutomaticLoginEnable=True\nAutomaticLogin=${live_user}" "$CHROOTNAME"/etc/X11/gdm/custom.conf
			fi
			;;
		"lightdm")
			sed -i -e "s/^#autologin-user=.*/autologin-user=live/g;s/^#autologin-session=.*/autologin-session=${SESSION,,}/g;s/^#user-session=.*/user-session=${SESSION,,}/g" "$CHROOTNAME"/etc/lightdm/lightdm.conf
			;;
		*)
			printf "%s -> ${DISPLAYMANAGER,,} is not supported, autologin feature will be not enabled"
		esac
		echo "XSession=${SESSION}" >>"$CHROOTNAME"/var/lib/AccountsService/users/${live_user}
	fi

	# (crazy) not used ? cannot work like this ?
	cd "$CHROOTNAME"/etc/sysconfig/network-scripts > /dev/null 2>&1
	for iface in eth0 wlan0; do
		cat > ifcfg-$iface << EOF
DEVICE=$iface
ONBOOT=yes
NM_CONTROLLED=yes
BOOTPROTO=dhcp
EOF
	done
	cd - > /dev/null 2>&1

	printf "%s\n" "-> Starting services setup."

	# (crazy) fixme after systemd is fixed..
	# (tpg) enable services based on preset files from systemd and others
	UNIT_DIR="$CHROOTNAME"/lib/systemd/system
	if [ -f "$UNIT_DIR-preset/90-default.preset" ]; then
		PRESETS=("$UNIT_DIR-preset"/*.preset)
		for file in "${PRESETS[@]}"; do
			while read line; do
				if [[ -n "$line" && "$line" != [[:blank:]#]* && "${line,,}" = [[:blank:]enable]* ]]; then
					SANITIZED="${line#*enable}"
					for s_file in $(/bin/find "$UNIT_DIR" -type f -name "$SANITIZED"); do
						DEST=$(grep -o 'WantedBy=.*' "$s_file"  | cut -f2- -d'=')
						if [ -n "$DEST" ] && [ -d "$CHROOTNAME/etc/systemd/system" ] && [ ! -e "$CHROOTNAME/etc/systemd/system/$DEST.wants/${s_file#$UNIT_DIR/}" ] ; then
							[ ! -d "/etc/systemd/system/$DEST.wants" ] && mkdir -p "$CHROOTNAME/etc/systemd/system/$DEST.wants"
							printf "%s\n" "-> Enabling ${s_file#$UNIT_DIR/} based on preset file"
							chroot "$CHROOTNAME" /bin/systemctl enable ${s_file#$UNIT_DIR/}
							#ln -sf "/${s_file#$CHROOTNAME/}" "$CHROOTNAME/etc/systemd/system/$DEST.wants/${s_file#$UNIT_DIR/}"
						else
							printf "%s\n" "-> All preset based service already enabled , moving on.."
						fi
					done
				fi
			done < "$file"
		done
	else
		# (crazy) that is wrong
		printf "%s\n" "-> File $UNIT_DIR-preset/90-default.preset does not exist. Installation may be broken"
		errorCatch
	fi

	# Enable services on demand
	# (crazy) WARNING: calamares-locale service need to run for langauage settings grub menu's
	# ( crazy) DO NOT ENABLE THESE: dnf-makecache.timer dnf-automatic.timer dnf-automatic-notifyonly.timer dnf-automatic-download.timer
	# like discussed 1000000000000 times already this should not be activate by default, not here not in the rpm. Not only it break the boot time but people are still
	# using 'paid' per MB/GB internet
	## this -> 17.153s dnf-makecache.service ( on a device boots in 2.4 secs with a nvme , imagine that on slow HDD )
	SERVICES_ENABLE=(getty@tty1.service sshd.socket uuidd.socket calamares-locale NetworkManager avahi-daemon.socket irqbalance systemd-timedated systemd-timesyncd systemd-resolved vboxadd vboxdrmclinet vboxdrmclinet.path spice-vdagentd)


	# ( crazy) we cannot symlink/rm for .service,.socket
	# these have , or may have dependecies in the unit file meaning,
	# if you rm/symlink foo it won't enable foo.dbus one or socket , same for disable.
	for i in "${SERVICES_ENABLE[@]}"; do
		if [[ $i  =~ ^.*path$|^.*target$|^.*timer$ ]]; then
			if [ -e "$CHROOTNAME/lib/systemd/system/$i" ]; then
				printf "%s\n" "-> Enabling $i"
				ln -sf "/lib/systemd/system/$i" "$CHROOTNAME/etc/systemd/system/multi-user.target.wants/$i"
			else
				printf "%s\n" "-> Special service $i does not exist. Skipping."
			fi
		else
			printf "%s\n" "-> Enabling $i"
			chroot "$CHROOTNAME" /bin/systemctl enable $i
		fi
	done

	# Disable services
	## be sure dnf* stuff is disabled!
	SERVICES_DISABLE=(dnf-makecache.timer dnf-automatic.timer dnf-automatic-notifyonly.timer dnf-automatic-download.timer pptp pppoe ntpd iptables ip6tables shorewall nfs-server mysqld abrtd mariadb mysql mysqld postfix NetworkManager-wait-online systemd-networkd systemd-networkd.socket nfs-utils chronyd udisks2 mdmonitor)

	for i in "${SERVICES_DISABLE[@]}"; do
		if [[ $i  =~ ^.*path$|^.*target$|^.*timer$ ]]; then
			if [ -e "$CHROOTNAME/lib/systemd/system/$i" ]; then
				printf "%s\n" "-> Disabling $i"
				rm -rf "$CHROOTNAME/etc/systemd/system/multi-user.target.wants/$i"
			else
				printf "%s\n" "-> Special service $i does not exist. Skipping."
			fi
		else
			printf "%s\n" "-> Disabling $i"
			chroot "$CHROOTNAME" /bin/systemctl disable $i
		fi
	done

	# it refuses to die :-)
	[ -e "$CHROOTNAME"/lib/systemd/system/multi-user.target.wants/systemd-networkd.service ] && rm -rf "$CHROOTNAME"/lib/systemd/system/multi-user.target.wants/systemd-networkd.service
	# mask systemd-journald-audit.socket to stop polluting journal with audit spam
	[ ! -e "$CHROOTNAME"/etc/systemd/system/systemd-journald-audit.socket ] && ln -sf /dev/null "$CHROOTNAME"/etc/systemd/system/systemd-journald-audit.socket

	# ATTENTION getty@.service must be always disabled
	[ -e "$CHROOTNAME"/etc/systemd/system/getty.target.wants/getty@.service ] && rm -rf "$CHROOTNAME"/etc/systemd/system/getty.target.wants/getty@.service

	# Calamares installer
	if [ -e "$CHROOTNAME"/etc/calamares/modules/displaymanager.conf ]; then
		# Enable settings for specific desktop environment
		# https://issues.openmandriva.org/show_bug.cgi?id=1424
		sed -i -e "s/.*defaultDesktopEnvironment:.*/defaultDesktopEnvironment:/g" "$CHROOTNAME/etc/calamares/modules/displaymanager.conf"

		## NOTE these sed's need generate valid yaml .. - crazy -
		if [ "${TYPE,,}" = 'plasma' -o "${TYPE,,}" = 'edu' ]; then
			sed -i -e "s/.*executable:.*/    executable: "startplasma-x11"/g" "$CHROOTNAME/etc/calamares/modules/displaymanager.conf"
			sed -i -e "s/.*desktopFile:.*/    desktopFile: "plasma"/g" "$CHROOTNAME/etc/calamares/modules/displaymanager.conf"
		fi

		if [ "${TYPE,,}" = 'plasma6' ]; then
			sed -i -e "s/.*executable:.*/    executable: "startplasma-wayland"/g" "$CHROOTNAME/etc/calamares/modules/displaymanager.conf"
			sed -i -e "s/.*desktopFile:.*/    desktopFile: "plasma"/g" "$CHROOTNAME/etc/calamares/modules/displaymanager.conf"
		elif [ "${TYPE,,}" = 'plasma6x11' ]; then
			sed -i -e "s/.*executable:.*/    executable: "startplasma-x11"/g" "$CHROOTNAME/etc/calamares/modules/displaymanager.conf"
			sed -i -e "s/.*desktopFile:.*/    desktopFile: "plasmax11"/g" "$CHROOTNAME/etc/calamares/modules/displaymanager.conf"
		elif [ "${TYPE,,}" = 'plasma-wayland' ]; then
			sed -i -e "s/.*executable:.*/    executable: "startplasmacompositor"/g" "$CHROOTNAME/etc/calamares/modules/displaymanager.conf"
			sed -i -e "s/.*desktopFile:.*/    desktopFile: "plasma-wayland"/g" "$CHROOTNAME/etc/calamares/modules/displaymanager.conf"
		elif [ "${TYPE,,}" = 'mate' ]; then
			sed -i -e "s/.*executable:.*/    executable: "mate-session"/g" "$CHROOTNAME/etc/calamares/modules/displaymanager.conf"
			sed -i -e "s/.*desktopFile:.*/    desktopFile: "mate"/g" "$CHROOTNAME/etc/calamares/modules/displaymanager.conf"
		elif [ "${TYPE,,}" = 'budgie' ]; then
			sed -i -e "s/.*executable:.*/    executable: "budgie-desktop"/g" "$CHROOTNAME/etc/calamares/modules/displaymanager.conf"
			sed -i -e "s/.*desktopFile:.*/    desktopFile: "budgie"/g" "$CHROOTNAME/etc/calamares/modules/displaymanager.conf"
		elif [ "${TYPE,,}" = 'cinnamon' ]; then
			sed -i -e "s/.*executable:.*/    executable: "cinnamon-session"/g" "$CHROOTNAME/etc/calamares/modules/displaymanager.conf"
			sed -i -e "s/.*desktopFile:.*/    desktopFile: "cinnamon"/g" "$CHROOTNAME/etc/calamares/modules/displaymanager.conf"
		elif [ "${TYPE,,}" = 'lxqt' ]; then
			sed -i -e "s/.*executable:.*/    executable: "lxqt-session"/g" "$CHROOTNAME/etc/calamares/modules/displaymanager.conf"
			sed -i -e "s/.*desktopFile:.*/    desktopFile: "lxqt"/g" "$CHROOTNAME/etc/calamares/modules/displaymanager.conf"
		elif [ "${TYPE,,}" = 'cutefish' ]; then
			sed -i -e "s/.*executable:.*/    executable: "cutefish-session"/g" "$CHROOTNAME/etc/calamares/modules/displaymanager.conf"
			sed -i -e "s/.*desktopFile:.*/    desktopFile: "cutefish"/g" "$CHROOTNAME/etc/calamares/modules/displaymanager.conf"
			elif [ "${TYPE,,}" = 'cosmic' ]; then
			sed -i -e "s/.*executable:.*/    executable: "start-cosmic"/g" "$CHROOTNAME/etc/calamares/modules/displaymanager.conf"
			sed -i -e "s/.*desktopFile:.*/    desktopFile: "cosmic"/g" "$CHROOTNAME/etc/calamares/modules/displaymanager.conf"
		elif [ "${TYPE,,}" = 'icewm' ]; then
			sed -i -e "s/.*desktopFile:.*/    desktopFile: "icewm"/g" "$CHROOTNAME/etc/calamares/modules/displaymanager.conf"
		elif [ "${TYPE,,}" = 'xfce' ]; then
			sed -i -e "s/.*executable:.*/    executable: "startxfce4"/g" "$CHROOTNAME/etc/calamares/modules/displaymanager.conf"
			sed -i -e "s/.*desktopFile:.*/    desktopFile: "xfce"/g" "$CHROOTNAME/etc/calamares/modules/displaymanager.conf"
		elif [ "${TYPE,,}" = 'gnome3' ]; then
			sed -i -e "s/.*executable:.*/    executable: "startgnome3"/g" "$CHROOTNAME/etc/calamares/modules/displaymanager.conf"
			sed -i -e "s/.*desktopFile:.*/    desktopFile: "gnome3"/g" "$CHROOTNAME/etc/calamares/modules/displaymanager.conf"
		elif [ "${TYPE,,}" = "$NEWTYPE" ]; then
			sed -i -e "s/.*executable:.*/    executable: $WMNAME/g" "$CHROOTNAME/etc/calamares/modules/displaymanager.conf"
			sed -i -e "s/.*desktopFile:.*/    desktopFile: $WMDESK/g" "$CHROOTNAME/etc/calamares/modules/displaymanager.conf"
		fi
	fi
	#remove rpm db files which may not match the non-chroot environment
	chroot "$CHROOTNAME" rm -f /var/lib/rpm/__db.*

	# Get back to real /etc/resolv.conf
	rm -f "$CHROOTNAME"/etc/resolv.conf
	ln -sf /run/systemd/resolve/stub-resolv.conf "$CHROOTNAME"/etc/resolv.conf
	# set up some default settings
	printf '%s\n' "nameserver 208.67.222.222" "nameserver 208.67.220.220" >> "$CHROOTNAME"/run/systemd/resolve/resolv.conf
	printf '%s\n' "nameserver 208.67.222.222" "nameserver 208.67.220.220" >> "$CHROOTNAME"/run/systemd/resolve/stub-resolv.conf

	# fontconfig cache
	if [ -x "$CHROOTNAME"/usr/bin/fc-cache ]; then
		# set the timestamp on the directories to be a whole second
		# fc-cache looks at the nano second portion which will otherwise be
		# non-zero as we are on ext4, but then it will compare against the stamps
		# on the squashfs live image, squashfs only has second level timestamp resolution
		FCTIME=$(date +%Y%m%d%H%M.%S)
		chroot "$CHROOTNAME" find /usr/share/fonts -type d -exec touch -t "$FCTIME" {} \;
		chroot "$CHROOTNAME" fc-cache -rf
		chroot "$CHROOTNAME" /bin/mkdir -p /root/.cache/fontconfig/
		chroot "$CHROOTNAME" /bin/mkdir -p /${live_user}/.cache/fontconfig/
	fi

	# Rebuild man-db
	if [ -x "$CHROOTNAME"/usr/bin/mandb ]; then
		printf "%s\n" "-> Please wait...rebuilding man page database"
		chroot "$CHROOTNAME" /usr/bin/mandb --quiet
	fi

	# Rebuild mime database
	if [ -x "$CHROOTNAME"/usr/bin/update-mime-database ]; then
		printf "%s\n" "-> Please wait...rebuilding MIME database"
		chroot "$CHROOTNAME" /usr/bin/update-mime-database /usr/share/mime
	fi

# Move the rpm cache out of the way for the iso build
	#if [[ "$ABF" = 0  || ( "$ABF" = '1' && -n "$DEBUG" ) ]]; then
	#if [ "$ABF" = 0 ] || [ "$ABF" = '1' ] && [ -n "$DEBUG" ]; then
	mv "$CHROOTNAME"/var/cache/dnf "$WORKDIR"/dnf
	mkdir -p "$CHROOTNAME"/var/cache/dnf
	#fi

	# (crazy) NOTE: this be after last think touched /home/live
	chroot "$CHROOTNAME" /bin/chown -R ${live_user}:${live_user} /home/${live_user}
	# Rebuild linker cache
	chroot "$CHROOTNAME" /sbin/ldconfig

	# Clear tmp
	rm -rf "$CHROOTNAME"/tmp/*
	rm -rf "$CHROOTNAME"/run/*
	rm -rf "$CHROOTNAME/1" ||:

	# Generate list of installed rpm packages
	chroot "$CHROOTNAME" rpm -qa --queryformat="%{NAME}\n" | sort > /var/lib/rpm/installed-by-default

	# Remove rpm db files to save some space
	rm -rf "$CHROOTNAME"/var/lib/rpm/__db.*

	for i in etc var; do
	    printf "%s\n" 'File created by omdv-build-iso. See systemd-update-done.service(8).' > "$CHROOTNAME/$i"/.updated
	done
}

# Clean out the backups of passwd, group and shadow
ClnShad() {
	/bin/rm -f "$CHROOTNAME"/etc/passwd- "$CHROOTNAME"/etc/group- "$CHROOTNAME"/etc/shadow-
	/bin/rm -f "$WORKDIR"/.new
}


createSquash() {
	printf "%s\n" "-> Starting squashfs image build."
	# Before we do anything check if we are a local build
	if [ "$ABF" = '0' ]; then
		# We are so make sure that nothing is mounted on the chroots /run/os-prober/dev/ directory.
		# If mounts exist mksquashfs will try to build a squashfs.img with contents of all  mounted drives
		# It's likely that the img will be written to one of the mounted drives so it's unlikely
		# that there will be enough diskspace to complete the operation.
		if [ -f "$ISOROOTNAME/run/os-prober/dev/*" ]; then
			umount -l "$(printf "%s\n" "$ISOROOTNAME/run/os-prober/dev/*")"
			if [ -f "$ISOROOTNAME/run/os-prober/dev/*" ]; then
				printf "%s\n" "-> Cannot unount os-prober mounts aborting."
				errorCatch
			fi
		fi
# copy the package lists and and the build options to the chroot
		mkdir -p ${CHROOTNAME}/.build_info
		cp ${COMMITDIR}/* ${CHROOTNAME}/.build_info/pkglsts_build_id-${BUILD_ID}
		dnf --installroot "${CHROOTNAME}" list --installed >${CHROOTNAME}/.build_info/installed_pkgs
	fi

	if [ -f "$ISOROOTNAME"/LiveOS/squashfs.img ]; then
		rm -rf "$ISOROOTNAME"/LiveOS/squashfs.img
	fi

	mkdir -p "$ISOROOTNAME"/LiveOS
	# Unmout all stuff inside CHROOT to build squashfs image
	umountAll "$CHROOTNAME"

# Build ISO image
	mksquashfs "$CHROOTNAME" "$ISOROOTNAME"/LiveOS/squashfs.img -comp zstd -Xcompression-level 15 -no-progress -no-exports -no-recovery -b 16384
	if [ ! -f  "$ISOROOTNAME"/LiveOS/squashfs.img ]; then
		printf "%s\n" "-> Failed to create squashfs." "Exiting."
		errorCatch
	fi

}

# Usage: buildIso filename.iso rootdir
# Builds an ISO file from the files in rootdir
buildIso() {
	printf "%s\n" "-> Starting ISO build."

	if [ "$ABF" = '1' ]; then
		ISOFILE="$WORKDIR/$PRODUCT_ID.$EXTARCH.iso"
	else
		if [ -z "$OUTPUTDIR" ]; then
			ISOFILE="$WORKDIR/$PRODUCT_ID.$EXTARCH.iso"
		else
			ISOFILE="$OUTPUTDIR/$PRODUCT_ID.$EXTARCH.iso"
		fi
	fi

	if [ ! -x /usr/bin/xorriso ]; then
		printf "%s\n" "-> xorriso does not exists. Exiting."
		errorCatch
	fi

	# Before starting to build remove the old iso. xorriso is much slower to create an iso
	# if it is overwriting an earlier copy. Also it's not clear whether this affects the.
	# contents or structure of the iso (see --append-partition in the man page)
	# Either way building the iso is 30 seconds quicker (for a 1G iso) if the old one is deleted.
	if [ "$ABF" = '0' ] && [ -n "$ISOFILE" ]; then
		printf "%s" "-> Removing old iso."
		rm -rf "$ISOFILE"
	fi
	printf "%s\n" "-> Building ISO with options ${XORRISO_OPTIONS}"

	xorriso -as mkisofs -R -r -J -joliet-long -cache-inodes \
		-graft-points -iso-level 3 -full-iso9660-filenames \
		--modification-date="${ISO_DATE}" \
		-omit-version-number -disable-deep-relocation \
		${XORRISO_OPTIONS} \
		-publisher "OpenMandriva Association" \
		-preparer "OpenMandriva Association" \
		-volid "$LABEL" -o "$ISOFILE" "$ISOROOTNAME" --sort-weight 0 / --sort-weight 1 /boot

	if [ ! -f "$ISOFILE" ]; then
		printf "%s\n" "-> Failed build iso image." "Exiting"
		errorCatch
	fi

	printf "%s\n" "-> ISO build completed."
}

postBuild() {
	if [ ! -f "$ISOFILE" ]; then
		umountAll "$CHROOTNAME"
		errorCatch
	fi
	# Count checksums
	printf "%s\n" "-> Generating ISO checksums."
	if [ -n "$OUTPUTDIR" ]; then
		cd "$OUTPUTDIR" || exit
		md5sum "$PRODUCT_ID.$EXTARCH.iso" > "$PRODUCT_ID.$EXTARCH.iso.md5sum"
		sha256sum "$PRODUCT_ID.$EXTARCH.iso" > "$PRODUCT_ID.$EXTARCH.iso.sha256sum"
	else
		cd "$WORKDIR" > /dev/null 2>&1
		md5sum "$PRODUCT_ID.$EXTARCH.iso" > "$PRODUCT_ID.$EXTARCH.iso.md5sum"
		sha256sum "$PRODUCT_ID.$EXTARCH.iso" > "$PRODUCT_ID.$EXTARCH.iso.sha256sum"
		cd - > /dev/null 2>&1
	fi

	mkdir -p "$WORKDIR/results" "$WORKDIR/archives"
	if [ -n "$OUTPUTDIR" ]; then
		mv "$OUTPUTDIR"/*.iso* "$WORKDIR/results/"
	else
		mv "$WORKDIR"/*.iso* "$WORKDIR/results/"
		if [ -d "$WORKDIR/sessrec/" ]; then
		cp -r "$WORKDIR"/sessrec/ "$WORKDIR/archives/"
		fi
	fi


	# If not in ABF move rpms back to the cache directories
	if [ "$ABF" = 0 ] || [ "$ABF" = '1' ] && [ -n "$DEBUG" ]; then
		/bin/rm -rf "$CHROOTNAME"/var/cache/dnf/
		mv -f "$WORKDIR"/dnf "$CHROOTNAME"/var/cache/
	fi

	# Clean chroot
	umountAll "$CHROOTNAME"
}

## (crazy) Fixme
umountAll() {
	printf "%s\n" "-> Unmounting all."
	unset KERNEL_ISO
	umount -l "$1"/proc 2> /dev/null || :
	umount -l "$1"/sys 2> /dev/null || :
	umount -l "$1"/dev/pts 2> /dev/null || :
	umount -l "$1"/dev 2> /dev/null || :
	umount -l "$1"/run/os-prober/dev/* 2> /dev/null || :
	umount -l "$IMGNME" 2> /dev/null || :
}

errorCatch() {
	printf "%s\n" "-> Something went wrong." "Exiting"
	FilterLogs
	unset KERNEL_ISO
	unset UEFI
	unset MIRRORLIST
	unset BOOT_KERNEL_ISO
	# (crazy) umountAll() ?
	umount -l /mnt
	losetup -D
	umountAll "$CHROOTNAME"
	umountAll "$CHROOTNAME"
	exit 1
}

# Don't leave potentially dangerous stuff if we had to error out...
trap errorCatch ERR SIGHUP SIGINT SIGTERM

FilterLogs() {
	printf "%s\n" "-> Make some helpful logs"
	if [ -f "$WORKDIR/install.log" ]; then
# Create the header
		printf "%s\n" "" "" "RPM Install Success" " " >"$WORKDIR/rpm-install.log"
		head -1 "$WORKDIR/install.log" | awk '{print$1"\t"$3"\t"$4"\t"$7"\t\t"$10}' >>"$WORKDIR/rpm-install.log" #1>&2 >/dev/null
		printf "%s\n" "" "" "RPM Install Failures" " " >"$WORKDIR/rpm-fail.log"
		head -1 "$WORKDIR/install.log" | awk '{print$1"\t"$3"\t"$4"\t"$7"\t\t"$10}' >>"$WORKDIR/rpm-fail.log"
# Append the data
		 awk '$7  ~ /1/  {print$1"\t"$3"\t"$4"\t\t"$7"\t"$18}' "$WORKDIR/install.log" >> "$WORKDIR/rpm-fail.log"
		 awk '$7  ~ /0/  {print$1"\t"$3"\t"$4"\t\t"$7"\t"$18}' "$WORKDIR/install.log" >> "$WORKDIR/rpm-install.log"
	fi

# Make a dependency failure log
	if [ -f "$WORKDIR/dnfopt.log" ]; then
		grep -hr -A1 '\[FAILED\]' "$WORKDIR/dnfopt.log" | sort -u > "$WORKDIR/depfail.log"
		MISSING=$(grep -hr -A1 'No match for argument' "$WORKDIR/dnfopt.log")
		printf "%s\n" "$MISSING" >missing-packages.log
	fi
	if [ "$ABF" = '1' ] && [ -f "$WORKDIR/install.log" ]; then
		cat "$WORKDIR/rpm-fail.log"
		printf "%s\n" " " "-> DEPENDENCY FAILURES"
		cat "$WORKDIR/depfail.log"
		cat "$WORKDIR/rpm-install.log"
	fi
# List the available repos and their status
	dnf repolist -C --installroot "$CHROOTNAME" --quiet  --all > REPO_STATUS.txt

}

main "$@"
