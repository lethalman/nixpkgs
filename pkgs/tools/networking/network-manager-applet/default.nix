{ stdenv, lib, fetchurl, intltool, pkgconfig, libglade, networkmanager, gnome3
, libnotify, libsecret-unstable, dbus_glib, polkit, isocodes, libgnome_keyring 
, mobile_broadband_provider_info, glib_networking, gsettings_desktop_schemas
, makeWrapper, networkmanager_openvpn, networkmanager_vpnc
, networkmanager_openconnect, networkmanager_pptp, udev, hicolor_icon_theme
, applet ? true, libnm-gtk ? null}:

let
  pn = "network-manager-applet";
  major = "1.0";
  version = networkmanager.version;
in

stdenv.mkDerivation rec {
  name = if applet then "network-manager-applet-${version}"
                   else "libnm-gtk-${version}";

  src = fetchurl {
    url = "mirror://gnome/sources/${pn}/${major}/${pn}-${version}.tar.xz";
    sha256 = "0liia390bhkl09lvk2rplcwhmfbxpjffa1xszfawc0h00v9fivaz";
  };

  buildInputs = lib.optional applet libnm-gtk ++ [
    gnome3.gtk libglade networkmanager libnotify libsecret-unstable dbus_glib gsettings_desktop_schemas
    polkit isocodes makeWrapper udev gnome3.gconf gnome3.libgnome_keyring
  ];

  nativeBuildInputs = [ intltool pkgconfig ];

  propagatedUserEnvPkgs = lib.optionals applet [ gnome3.gconf gnome3.gnome_keyring hicolor_icon_theme ];

  makeFlags = [
    ''CFLAGS=-DMOBILE_BROADBAND_PROVIDER_INFO=\"${mobile_broadband_provider_info}/share/mobile-broadband-provider-info/serviceproviders.xml\"''
  ];

  postInstall = if applet then ''
    make -C src/libnm-gtk uninstall
  '' else ''
    rm -r $out/bin
    rm -r $out/libexec
    rm -r $out/share
    rm -r $out/etc
    rm -r $out/lib/gdk-pixbuf-loaders-2.0
  '';

  postFixup = lib.optionalString applet ''
    for prog in $out/bin/nm-applet $out/bin/nm-connection-editor $out/libexec/nm-applet-migration-tool; do
      patchelf --set-rpath "$(patchelf --print-rpath $prog):${libnm-gtk}/lib" $prog
    done

    wrapProgram "$out/bin/nm-applet" \
      --prefix GIO_EXTRA_MODULES : "${glib_networking}/lib/gio/modules:${gnome3.dconf}/lib/gio/modules" \
      --prefix XDG_DATA_DIRS : "${gnome3.gtk}/share:$out/share:$GSETTINGS_SCHEMAS_PATH" \
      --set GCONF_CONFIG_SOURCE "xml::~/.gconf" \
      --prefix PATH ":" "${gnome3.gconf}/bin"
    wrapProgram "$out/bin/nm-connection-editor" \
      --prefix XDG_DATA_DIRS : "${gnome3.gtk}/share:$out/share:$GSETTINGS_SCHEMAS_PATH"
  '';

  meta = with stdenv.lib; {
    homepage = http://projects.gnome.org/NetworkManager/;
    description = if applet then "NetworkManager control applet for GNOME"
                            else "GTK wrapper for NetworkManager DBus API";
    license = licenses.gpl2;
    maintainers = with maintainers; [ phreedom urkud rickynils cstrahan ];
    platforms = platforms.linux;
  };
}
