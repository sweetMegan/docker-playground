#
# spec file for package libosmo-sccp
#
# Copyright (c) 2018 SUSE LINUX GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

%define libversion %(echo "%{version}" |sed 's/\\./_/g')
Name:           libosmo-sccp
Version:        1.2.0.35
Release:        0
Summary:        Osmocom library for the A-bis interface between BTS and BSC
License:        AGPL-3.0-or-later AND GPL-2.0-or-later
Group:          Hardware/Mobile
URL:            https://projects.osmocom.org/projects/libosmo-sccp
#Git-Clone:	git://git.osmocom.org/libosmo-sccp
Source:         %{name}-%{version}.tar.xz
Patch0:         0001-build-fixes.patch
BuildRequires:  automake >= 1.6
BuildRequires:  libtool >= 2
BuildRequires:  lksctp-tools-devel
BuildRequires:  pkgconfig >= 0.20
%if 0%{?suse_version} >= 1210
BuildRequires:  systemd-rpm-macros
%endif
BuildRequires:  xz
BuildRequires:  pkgconfig(libosmo-netif) >= 0.4.0
BuildRequires:  pkgconfig(libosmocore) >= 1.0.0
BuildRequires:  pkgconfig(libosmogsm) >= 1.0.0
BuildRequires:  pkgconfig(libosmovty) >= 1.0.0

%description
SCCP is a network layer protocol that provides extended routing, flow
control, segmentation, connection-orientation, and error correction
facilities in Signaling System 7 telecommunications networks. SCCP is
heavily used in cellular networks such as GSM.

%package -n libosmo-mtp-%{libversion}
Summary:        Osmocom Message Transfer Part library
License:        GPL-2.0-or-later
Group:          System/Libraries

%description -n libosmo-mtp-%{libversion}
The Message Transfer Part (MTP) is part of the Signaling System 7
(SS7) used for communication in Public Switched Telephone Networks.
MTP is responsible for reliable, unduplicated and in-sequence
transport of SS7 messages between communication partners.

%package -n libosmo-mtp-devel
Summary:        Development files for the Osmocom MTP library
License:        GPL-2.0-or-later
Group:          Development/Libraries/C and C++
Requires:       libosmo-mtp-%{libversion} = %{version}

%description -n libosmo-mtp-devel
MTP is part of SS7 used for communication in Public Switched
Telephone Networks.

This subpackage contains the development files for the Osmocom MTP
library.

%package -n libosmo-sccp-%{libversion}
Summary:        Osmocom Signalling Connection Control Part library
License:        GPL-2.0-or-later
Group:          System/Libraries

%description -n libosmo-sccp-%{libversion}
The Signalling Connection Control Part (SCCP) is a network layer
protocol that provides extended routing, flow control, segmentation,
connection-orientation, and error correction facilities in Signaling
System 7 telecommunications networks. SCCP relies on the services of
MTP for basic routing and error detection.

%package -n libosmo-sccp-devel
Summary:        Development files for the Osmocom SCCP library
License:        GPL-2.0-or-later
Group:          Development/Libraries/C and C++
Requires:       libosmo-sccp-%{libversion} = %{version}

%description -n libosmo-sccp-devel
SCCP is a network layer protocol that provides routing, flow control,
segmentation, connection-orientation, and error correction facilities
in SS7 telecommunications networks.

This subpackage contains the development files for the Osmocom SCCP
library.

%package -n libosmo-sigtran5
Summary:        Osmocom SIGTRAN library
License:        GPL-2.0-or-later
Group:          System/Libraries

%description -n libosmo-sigtran5
Osmocom implementation of (parts of) SIGTRAN.

%package -n libosmo-sigtran-devel
Summary:        Development files for the Osmocom sigtran library
License:        GPL-2.0-or-later
Group:          Development/Libraries/C and C++
Requires:       libosmo-sigtran5 = %{version}

%description -n libosmo-sigtran-devel
Osmocom implementation of (parts of) SIGTRAN.

This subpackage contains the development files for the Osmocom
SIGTRAN library.

%package -n libosmo-xua-%{libversion}
Summary:        Osmocom Message Transfer Part 2 User Adaptation library
License:        GPL-2.0-or-later
Group:          System/Libraries

%description -n libosmo-xua-%{libversion}
M2UA (RFC 3331) provides an SCTP (RFC 3873) adaptation layer for the
seamless backhaul of MTP Level 2 user messages and service interface
across an IP network.

%package -n libosmo-xua-devel
Summary:        Development files for the Osmocom M2UA library
License:        GPL-2.0-or-later
Group:          Development/Libraries/C and C++
Requires:       libosmo-sigtran-devel = %{version}
Requires:       libosmo-xua-%{libversion} = %{version}

%description -n libosmo-xua-devel
M2UA provides an SCTP adaptation layer for MTP level 2 user messages
and service interface across an IP network.

This subpackage contains the development files for the Osmocom M2UA
library.

%package -n osmo-stp
Summary:        Osmocom SIGTRAN STP (Signaling Transfer Point)
License:        GPL-2.0-or-later
Group:          Productivity/Telephony/Servers

%description -n osmo-stp
This is the Osmocom (Open Source Mobile Communications) implementation
of a Signaling Transfer Point (STP) for SS7/SIGTRAN telecommunication
networks. At this point it is a very minimal implementation, missing
lots of the functionality usually present in a STP, such as Global Title
Routing, Global Title Translation.

%prep
%setup -q
%patch0 -p1

%build
echo "%{version}" >.tarball-version
autoreconf -fiv
%configure \
    --enable-shared \
    --disable-static \
    --includedir="%{_includedir}/%{name}" \
    --docdir="%{_docdir}/%{name}" \
    --with-systemdsystemunitdir=%{_unitdir}
make %{?_smp_mflags}

%install
%make_install
find %{buildroot} -type f -name "*.la" -delete -print

%check
make %{?_smp_mflags} check || (find . -name testsuite.log -exec cat {} +)

%post   -n libosmo-mtp-%{libversion} -p /sbin/ldconfig
%postun -n libosmo-mtp-%{libversion} -p /sbin/ldconfig
%post   -n libosmo-sccp-%{libversion} -p /sbin/ldconfig
%postun -n libosmo-sccp-%{libversion} -p /sbin/ldconfig
%post   -n libosmo-sigtran5 -p /sbin/ldconfig
%postun -n libosmo-sigtran5 -p /sbin/ldconfig
%post   -n libosmo-xua-%{libversion} -p /sbin/ldconfig
%postun -n libosmo-xua-%{libversion} -p /sbin/ldconfig
%preun  -n osmo-stp %service_del_preun osmo-stp.service
%postun -n osmo-stp %service_del_postun osmo-stp.service
%pre    -n osmo-stp %service_add_pre osmo-stp.service
%post   -n osmo-stp %service_add_post osmo-stp.service

%files -n libosmo-mtp-%{libversion}
%{_libdir}/libosmo-mtp-%{version}.so

%files -n libosmo-mtp-devel
%dir %{_includedir}/%{name}
%dir %{_includedir}/%{name}/osmocom
%{_includedir}/%{name}/osmocom/mtp/
%{_libdir}/libosmo-mtp.so
%{_libdir}/pkgconfig/libosmo-mtp.pc

%files -n libosmo-sccp-%{libversion}
%{_libdir}/libosmo-sccp.so
%{_libdir}/libosmo-sccp-%{version}.so

%files -n libosmo-sccp-devel
%dir %{_includedir}/%{name}
%dir %{_includedir}/%{name}/osmocom
%{_includedir}/%{name}/osmocom/sccp/
%{_libdir}/pkgconfig/libosmo-sccp.pc

%files -n libosmo-sigtran5
%{_libdir}/libosmo-sigtran.so.5*

%files -n libosmo-sigtran-devel
%dir %{_includedir}/%{name}
%dir %{_includedir}/%{name}/osmocom
%{_includedir}/%{name}/osmocom/sigtran
%{_libdir}/libosmo-sigtran.so
%{_libdir}/pkgconfig/libosmo-sigtran.pc

%files -n libosmo-xua-%{libversion}
%{_libdir}/libosmo-xua-%{version}.so

%files -n libosmo-xua-devel
%{_libdir}/libosmo-xua.so
%{_libdir}/pkgconfig/libosmo-xua.pc

%files -n osmo-stp
%{_bindir}/osmo-stp
%dir %{_sysconfdir}/osmocom
%config %{_sysconfdir}/osmocom/osmo-stp.cfg
%{_unitdir}/osmo-stp.service
%dir %{_docdir}/%{name}
%dir %{_docdir}/%{name}/examples
%dir %{_docdir}/%{name}/examples/osmo-stp
%{_docdir}/%{name}/examples/osmo-stp/osmo-stp.cfg
%{_docdir}/%{name}/examples/osmo-stp/osmo-stp-multihome.cfg

%changelog
