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
Requires:       gtk4
Requires:       gtk4-layer-shell
Requires:       ydotool
# Dictation button: parecord records the mic, wl-copy backs output "paste".
Recommends:     pulseaudio-utils
Suggests:       wl-clipboard

%description
A row of tappable buttons (Esc, Tab, Ctrl+C, arrows and more) that shows up
alongside the on-screen keyboard and injects real key chords through ydotool
(kernel uinput). It is a single Python 3 executable built on GTK 4 and
gtk4-layer-shell, handy on touch devices where a terminal needs keys the
virtual keyboard does not offer. An optional dictation button transcribes
speech offline with an open model (whisper.cpp) and types the result, and
can be started hands-free with a wake phrase (kde-keybar-wake, which needs
Vosk in a user venv; see the docs).

%prep
%autosetup

%build
# Nothing to build, kde-keybar is a plain Python script.

%install
rm -rf %{buildroot}

install -Dpm 0755 kde-keybar %{buildroot}%{_bindir}/kde-keybar
install -Dpm 0755 kde-keybar-wake %{buildroot}%{_bindir}/kde-keybar-wake
install -Dpm 0644 data/kde-keybar.desktop %{buildroot}%{_sysconfdir}/xdg/autostart/kde-keybar.desktop
install -Dpm 0644 data/ydotoold.service %{buildroot}%{_unitdir}/ydotoold.service
install -Dpm 0644 data/kde-keybar.service %{buildroot}%{_userunitdir}/kde-keybar.service
install -Dpm 0644 config/kde-keybar.example.json %{buildroot}%{_docdir}/%{name}/kde-keybar.example.json
install -Dpm 0644 LICENSE %{buildroot}%{_licensedir}/%{name}/LICENSE
install -Dpm 0644 kwin/kde-keybar-fit/metadata.json %{buildroot}%{_datadir}/kwin/scripts/kde-keybar-fit/metadata.json
install -Dpm 0644 kwin/kde-keybar-fit/contents/code/main.js %{buildroot}%{_datadir}/kwin/scripts/kde-keybar-fit/contents/code/main.js

%files
%license %{_licensedir}/%{name}/LICENSE
%{_bindir}/kde-keybar
%{_bindir}/kde-keybar-wake
%config(noreplace) %{_sysconfdir}/xdg/autostart/kde-keybar.desktop
%{_unitdir}/ydotoold.service
%{_userunitdir}/kde-keybar.service
%dir %{_docdir}/%{name}
%doc %{_docdir}/%{name}/kde-keybar.example.json
%{_datadir}/kwin/scripts/kde-keybar-fit/

%changelog
* Fri Jul 10 2026 thereisnotime <thereisnotime@users.noreply.github.com> - 0.1.0-1
- Initial package.
