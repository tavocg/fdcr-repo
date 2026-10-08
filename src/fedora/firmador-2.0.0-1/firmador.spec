Name:           firmador
Version:        2.0.0
Release:        1%{?dist}
Summary:        Firmador Libre de documentos para Costa Rica
License:        GPL-3.0-or-later
URL:            https://firmador.libre.cr/
Source0:        payload.tar.gz
BuildArch:      noarch

Requires:       bash
Requires:       java-21-openjdk
Requires:       pcsc-lite-libs
Recommends:     idopte-p11

%description
Firma digital de documentos con tarjetas y módulos PKCS#11.

%prep

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}
tar -xzf %{SOURCE0} -C %{buildroot}

%files
/usr/bin/firmador
/usr/share/applications/firmador.desktop
%license /usr/share/doc/firmador/copyright
%doc /usr/share/doc/firmador/AUTHORS.md
/usr/share/firmador
/usr/share/icons/hicolor/128x128/apps/firmador.png
/usr/share/icons/hicolor/1024x1024/apps/firmador.png

%changelog
* Thu Oct 08 2026 Soporte Firma Digital - 2.0.0-1
- Initial RPM package.
