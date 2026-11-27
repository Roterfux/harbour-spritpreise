Name:       harbour-spritpreise
Version:    0.1.1
Release:    1
Summary:    Cheapest fuel prices in Austria
License:    MIT
URL:        https://github.com/Roterfux/harbour-spritpreise
Source0:    %{name}-%{version}.tar.bz2
Requires:   sailfishsilica-qt5 >= 0.10.9
BuildRequires: pkgconfig(sailfishapp) >= 1.0.2
BuildRequires: pkgconfig(Qt5Core)
BuildRequires: pkgconfig(Qt5Qml)
BuildRequires: pkgconfig(Qt5Quick)
BuildRequires: pkgconfig(Qt5Network)
BuildRequires: desktop-file-utils

%description
Shows the cheapest petrol stations near an address or in a region of
Austria, using the official E-Control Spritpreisrechner data.

%prep
%autosetup

%build
%qmake5 %{name}.pro
%make_build

%install
%qmake5_install

%files
%{_bindir}/%{name}
%{_datadir}/%{name}/
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png

%changelog
* Fri Nov 27 2026 Roterfux - 0.1.1-1
- Station details show "closed" and "24 hours" instead of raw 00:00 times
- Station, region and address search checked against the live E-Control API
