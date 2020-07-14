Summary:	Tool to build OopenMandriva ISO
Name:		omdv-build-iso
# (tpg) befor you release please make sure you updated sources
# make dist
# abf store omdv-build-iso*.tar.xz
# update .abf.yml
Version:	4.1.0
Release:	1
License:	GPL
Group:		System/Libraries
URL:		https://abf.io/openmandriva/omdv-build-iso
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
Requires:	syslinux
Requires:	diffutils
Requires:	parallel
BuildArch:	noarch

%description
Tool to build OpenMandriva Lx ISO.

%prep
%setup -q

%build
#nothing to do here

%install
%makeinstall_std

%files
%doc README.md ChangeLog
%dir %{_datadir}/%{name}
%{_bindir}/%{name}.sh
%{_datadir}/%{name}/*

