Name:           bccr-gaudi
Version:        29.0
Release:        1%{?dist}
Summary:        Agente GAUDI del Banco Central de Costa Rica
License:        Proprietary
URL:            https://www.soportefirmadigital.com/
Source0:        payload.tar.gz
BuildArch:      x86_64
AutoReqProv:    no

Provides:       agente-gaudi = %{version}-%{release}
Conflicts:      Agente-GAUDI
Obsoletes:      Agente-GAUDI <= 29.0-1

Requires:       alsa-lib
Requires:       atk
Requires:       cairo
Requires:       fontconfig
Requires:       freetype
Requires:       glibc
Requires:       gdk-pixbuf2
Requires:       glib2
Requires:       gtk2
Requires:       gtk3
Requires:       libX11
Requires:       libXext
Requires:       libXi
Requires:       libXrender
Requires:       libXtst
Requires:       libXxf86vm
Requires:       mesa-libGL
Requires:       libgcc
Requires:       libstdc++
Requires:       pango
Requires:       pcsc-lite
Requires:       pcsc-lite-libs
Requires:       xdg-utils
Requires:       zlib

%description
Agente GAUDI para firma digital del Banco Central de Costa Rica, con el
entorno Java suministrado por el proveedor.

%prep

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}
tar -xzf %{SOURCE0} -C %{buildroot}

%files
/opt/Agente-GAUDI
/usr/share/applications/Agente-GAUDI.desktop
%config(noreplace) /etc/xdg/autostart/Agente-GAUDI.desktop
%license /usr/share/licenses/Agente-GAUDI-29.0/licence.md

%changelog
* Thu Oct 08 2026 Soporte Firma Digital - 29.0-1
- Initial Fedora package.
