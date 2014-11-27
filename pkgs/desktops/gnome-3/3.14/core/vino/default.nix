{ stdenv, intltool, fetchurl, gtk3, glib, libsoup, pkgconfig, makeWrapper
, hicolor_icon_theme, gnome3
, libnotify, file, telepathy_glib, dbus_glib }:

stdenv.mkDerivation rec {
  name = "vino-${versionMajor}.${versionMinor}";
  versionMajor = gnome3.version;
  versionMinor = "1";

  src = fetchurl {
    url = "mirror://gnome/sources/vino/${versionMajor}/${name}.tar.xz";
    sha256 = "712bbb220cc16a9822a0617ae9ceb0fe8b326d5b3428210af7afe77effbbca8a";
  };

  doCheck = true;

  buildInputs = [ gtk3 intltool glib libsoup pkgconfig libnotify
                  hicolor_icon_theme gnome3.adwaita-icon-theme
                  dbus_glib telepathy_glib file makeWrapper ];

  preFixup = ''
    wrapProgram "$out/libexec/vino-server" \
      --prefix XDG_DATA_DIRS : "$out/share:$XDG_ICON_DIRS:$GSETTINGS_SCHEMAS_PATH"
  '';

  meta = with stdenv.lib; {
    homepage = https://wiki.gnome.org/action/show/Projects/Vino;
    description = "GNOME desktop sharing server";
    maintainers = with maintainers; [ lethalman iElectric ];
    license = licenses.gpl2;
    platforms = platforms.linux;
  };
}
