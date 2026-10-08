Name:           bccr-certs
Version:        2026.08
Release:        1%{?dist}
Summary:        Certificados de la jerarquía nacional de Firma Digital de Costa Rica
License:        LicenseRef-BCCR-Certificate-Data
URL:            https://www.soportefirmadigital.com/
Source0:        payload.tar.gz
BuildArch:      noarch

Requires:       ca-certificates
Requires:       openssl

%description
Certificados BCCR y certificados raíz en el trust store del sistema.

%prep

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}
tar -xzf %{SOURCE0} -C %{buildroot}

%post
/usr/libexec/bccr-certs/install /usr/share/pki/ca-trust-source/anchors fedora

%preun
if [ "$1" -eq 0 ]; then
  /usr/libexec/bccr-certs/remove /usr/share/pki/ca-trust-source/anchors fedora
fi

%files
/usr/libexec/bccr-certs/install
/usr/libexec/bccr-certs/remove
/usr/share/bccr-certs/originals

%changelog
* Thu Oct 08 2026 Soporte Firma Digital - 2026.08-1
- Initial RPM package.
