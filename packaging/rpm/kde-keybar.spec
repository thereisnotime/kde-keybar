Name:           kde-keybar
Version:        0.1.0
Release:        1%{?dist}
Summary:        On-screen key strip for KDE Plasma Wayland

License:        MIT
URL:            https://github.com/thereisnotime/kde-keybar
Source0:        %{name}-%{version}.tar.gz

BuildArch:      noarch

Requires:       python3
Requires:       python3-gobject
Requires:       gtk3
Requires:       gtk-layer-shell
Requires:       ydotool

%description
A row of tappable buttons (Esc, Tab, Ctrl+C, arrows and more) that shows up
alongside the on-screen keyboard and injects real key chords through ydotool
(kernel uinput). It is a single Python 3 executable built on GTK3 and
gtk-layer-shell, handy on touch devices where a terminal needs keys the
virtual keyboard does not offer.

%prep
%autosetup

%build
# Nothing to build, kde-keybar is a plain Python script.

%install
rm -rf %{buildroot}

install -Dpm 0755 kde-keybar %{buildroot}%{_bindir}/kde-keybar
install -Dpm 0644 data/kde-keybar.desktop %{buildroot}%{_sysconfdir}/xdg/autostart/kde-keybar.desktop
install -Dpm 0644 data/ydotoold.service %{buildroot}%{_unitdir}/ydotoold.service
install -Dpm 0644 config/kde-keybar.example.json %{buildroot}%{_docdir}/%{name}/kde-keybar.example.json
install -Dpm 0644 LICENSE %{buildroot}%{_licensedir}/%{name}/LICENSE

%files
%license %{_licensedir}/%{name}/LICENSE
%{_bindir}/kde-keybar
%config(noreplace) %{_sysconfdir}/xdg/autostart/kde-keybar.desktop
%{_unitdir}/ydotoold.service
%dir %{_docdir}/%{name}
%doc %{_docdir}/%{name}/kde-keybar.example.json

%changelog
* Fri Jul 10 2026 thereisnotime <thereisnotime@users.noreply.github.com> - 0.1.0-1
- Initial package.
