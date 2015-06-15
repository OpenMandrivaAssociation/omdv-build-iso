Summary:	Tool to build OopenMandriva ISO
Name:		omdv-build-iso
# (tpg) befor you release please make sure you updated sources
# make dist
# abf store omdv-build-iso*.tar.xz
# update .abf.yml
Version:	0.0.5.6
Release:	2
License:	GPL
Group:		System/Libraries
URL:		https://abf.io/openmandriva/omdv-build-iso
Source0:	%{name}-%{version}.tar.xz
Requires:	bash
Requires:	dosfstools
Requires:	urpmi
Requires:	squashfs-tools
Requires:	xorriso
Requires:	wget
Requires:	tar
Requires:	util-linux
Requires:	coreutils
Requires:	timezone
BuildArch:	noarch

%description
Tool to build OopenMandriva ISO.

%prep
%setup -q

%build
#nothing to do here

%install
%makeinstall_std

%files
%doc README ChangeLog
%dir %{_datadir}/%{name}
%{_bindir}/%{name}.sh
%{_datadir}/%{name}/*
