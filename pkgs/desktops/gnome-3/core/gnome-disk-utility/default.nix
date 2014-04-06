{ stdenv, intltool, fetchurl, pkgconfig, udisks2, libsecret, libdvdread
, bash, gtk3, glib, hicolor_icon_theme, makeWrapper, cracklib, libnotify
, itstool, gnome3, librsvg, gdk_pixbuf, libxml2, python
, libcanberra_gtk3, libxslt, libtool, docbook_xsl, libpwquality }:

stdenv.mkDerivation rec {
  name = "gnome-disk-utility-3.12.0";

  src = fetchurl {
    url = "mirror://gnome/sources/gnome-disk-utility/3.12/${name}.tar.xz";
    sha256 = "46e0698c4a7baa8719a79935066e103447011fb47528a28dbb49e35eeec409d8";
  };

  doCheck = true;

  NIX_CFLAGS_COMPILE = "-I${gnome3.glib}/include/gio-unix-2.0";

  propagatedUserEnvPkgs = [ gnome3.gnome_themes_standard ];
  propagatedBuildInputs = [ gdk_pixbuf gnome3.gnome_icon_theme
                            librsvg udisks2 gnome3.gnome_settings_daemon
                            hicolor_icon_theme gnome3.gnome_icon_theme_symbolic ];

  buildInputs = [ bash pkgconfig gtk3 glib intltool itstool
                  libxslt libtool libsecret libpwquality cracklib
                  libnotify libdvdread libcanberra_gtk3 docbook_xsl
                  gnome3.gsettings_desktop_schemas makeWrapper libxml2 ];

  installFlags = "gsettingsschemadir=\${out}/share/gnome-disk-utility/glib-2.0/schemas/";

  postInstall = ''
    wrapProgram "$out/bin/gnome-disks" \
      --set GDK_PIXBUF_MODULE_FILE "$GDK_PIXBUF_MODULE_FILE" \
      --prefix XDG_DATA_DIRS : "${gtk3}/share:${gnome3.gnome_themes_standard}/share:${gnome3.gsettings_desktop_schemas}/share:$out/share:$out/share/gnome-disk-utility:$XDG_ICON_DIRS"
  '';

  preFixup = ''
    rm $out/share/icons/hicolor/icon-theme.cache
  '';

  meta = with stdenv.lib; {
    homepage = http://en.wikipedia.org/wiki/GNOME_Disks;
    description = "A udisks graphical front-end";
    maintainers = with maintainers; [ lethalman ];
    license = licenses.gpl2;
    platforms = platforms.linux;
  };
}
