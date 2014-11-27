{ stdenv, intltool, fetchurl, gdk_pixbuf, tracker
, python3, libxml2, python3Packages, libnotify
, pkgconfig, gtk3, glib, hicolor_icon_theme, cairo
, makeWrapper, itstool, gnome3, librsvg, gst_all_1 }:

stdenv.mkDerivation rec {
  name = "gnome-music-${gnome3.version}.2";

  src = fetchurl {
    url = "mirror://gnome/sources/gnome-music/${gnome3.version}/${name}.tar.xz";
    sha256 = "f322897cabfab464e424ab7ff3c7d759912c977b365009dc02f074cf971afb35";
  };

  propagatedUserEnvPkgs = [ gnome3.gnome_themes_standard ];

  buildInputs = [ pkgconfig gtk3 glib intltool itstool gnome3.libmediaart
                  gdk_pixbuf gnome3.adwaita-icon-theme librsvg python3
                  gnome3.grilo libxml2 python3Packages.pygobject3 libnotify
                  python3Packages.pycairo python3Packages.dbus gnome3.totem-pl-parser
                  gst_all_1.gstreamer gst_all_1.gst-plugins-base
                  gst_all_1.gst-plugins-good gst_all_1.gst-plugins-bad
                  hicolor_icon_theme gnome3.adwaita-icon-theme
                  gnome3.gsettings_desktop_schemas makeWrapper tracker ];

  enableParallelBuilding = true;

  preFixup =
    let
      libPath = stdenv.lib.makeLibraryPath
        [ glib gtk3 libnotify tracker gnome3.grilo cairo
          gst_all_1.gstreamer gst_all_1.gst-plugins-base gnome3.totem-pl-parser
          gst_all_1.gst-plugins-good gst_all_1.gst-plugins-bad ];
    in
    ''
    wrapProgram "$out/bin/gnome-music" \
      --set GDK_PIXBUF_MODULE_FILE "$GDK_PIXBUF_MODULE_FILE" \
      --prefix XDG_DATA_DIRS : "${gnome3.gnome_themes_standard}/share:$XDG_ICON_DIRS:$GSETTINGS_SCHEMAS_PATH" \
      --prefix GI_TYPELIB_PATH : "$GI_TYPELIB_PATH" \
      --prefix LD_LIBRARY_PATH : "${libPath}" \
      --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "$GST_PLUGIN_SYSTEM_PATH_1_0" \
      --prefix GRL_PLUGIN_PATH : "${gnome3.grilo-plugins}/lib/grilo-0.2" \
      --prefix PYTHONPATH : "$PYTHONPATH"
  '';

  meta = with stdenv.lib; {
    homepage = https://wiki.gnome.org/Apps/Music;
    description = "Music player and management application for the GNOME desktop environment";
    maintainers = with maintainers; [ lethalman ];
    license = licenses.gpl2;
    platforms = platforms.linux;
  };
}
