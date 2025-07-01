Summary:	Tool to build OopenMandriva ISO
Name:		omdv-build-iso
# (tpg) before you do the release, please be sure you updated sources
# make dist
# abf store omdv-build-iso*.tar.xz
# update .abf.yml
Version:	4.1.3
Release:	7
License:	GPL
Group:		System/Libraries
URL:		https://github.com/OpenMandrivaAssociation/omdv-build-iso
# (tpg) this file is generate by running "make dist"
# make sure VERSION is good in Makefile
Source0:	%{name}-%{version}.tar.xz
Requires:	bash
Requires:	bc
Requires:	dosfstools
Requires:	dnf
Requires:	squashfs-tools >= 4.3-9
Requires:	xorriso
Requires:	wget
Requires:	tar
Requires:	util-linux
Requires:	coreutils
Requires:	timezone
Requires:	imagemagick
Requires:	gptfdisk
Requires:	kpartx
Requires:	grub2
Requires:	diffutils
Requires:	parallel
BuildArch:	noarch

%description
Tool to build OpenMandriva Lx ISO.

%prep
%autosetup -p1

%build
#nothing to do here

%install
%make_install

%files
%doc README.md 
# ChangeLog
%dir %{_datadir}/%{name}
%{_bindir}/%{name}.sh
%{_datadir}/%{name}/*
