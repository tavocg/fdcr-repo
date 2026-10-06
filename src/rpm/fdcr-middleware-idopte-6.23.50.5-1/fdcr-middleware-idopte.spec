Name:           fdcr-middleware-idopte
Version:        6.23.50.5
Release:        1%{?dist}
Summary:        Middleware PKCS#11 Idopte para firma digital de Costa Rica
License:        Proprietary
URL:            https://www.soportefirmadigital.com/
Source0:        payload.tar.gz
BuildArch:      x86_64

Requires:       glibc >= 2.38
Requires:       libstdc++ >= 13.2
Requires:       libgcc
Requires:       pcsc-lite-libs >= 1.7
Requires:       libxml2 >= 2.7.3
Requires:       zlib >= 1.2.3.4
Requires:       pcsc-lite
Requires:       pcsc-lite-ccid

%description
Middleware PKCS#11 Idopte para firma digital de Costa Rica.

%prep

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}
tar -xzf %{SOURCE0} -C %{buildroot}

%files
%config(noreplace) /etc/idoss.conf
%config(noreplace) /etc/idoss.lic
/usr/lib/SCMiddleware
/usr/share/SCMiddleware
/usr/share/applications/pkcs7.desktop
/usr/share/mime/packages/pkcs7-mime.xml
/usr/share/nautilus-python/extensions/CryptoshellExtension.py

%changelog
* Mon Oct 05 2026 Soporte Firma Digital - 6.23.50.5-1
- Initial RPM package.
