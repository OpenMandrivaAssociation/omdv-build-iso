Summary:	Tool to build OopenMandriva ISO
Name:		omdv-build-iso
Version:	0.0.1
Release:	1
License:	GPL
Group:		System/Libraries
URL:		https://abf.io/openmandriva/omdv-build-iso
#Source0:	%{name}-%{version}.tar.xz
Requires:	bash
Requires:	urpmi
Requires:	squashfs-tools
Requires:	xorriso
Requires:	wget
Requires:	tar
Requires:	util-linux
Requires:	coreutils
Requires:	timezone

%description
Tool to build OopenMandriva ISO.

%prep
%setup -q

%build
#nothing to do here

%install
%makeinstall_std

%files
%doc ChangeLog
%dir %{_datadir}/%{name}
%{_bindir}/%{name}
%{_datadir}/%{name}/*
