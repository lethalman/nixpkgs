{ stdenv, fetchurl, intltool, autoreconfHook, pkgconfig, vala, glib
, pango, gtk3, gnome3, dbus, clutter, appdata-tools, makeWrapper }:

stdenv.mkDerivation rec {
  version = "${gnome3.version}";
  name = "gpaste-${version}";

  src = fetchurl {
    url = "https://github.com/Keruspe/GPaste/archive/v${version}.tar.gz";
    sha256 = "1gfvw8n9ihi4wk90hcv8qp526zhlhmkbvgmdi1gwavvmxix59mjm";
  };

  buildInputs = [ intltool autoreconfHook pkgconfig vala glib
                  gtk3 gnome3.gnome_control_center dbus.libs
                  clutter pango appdata-tools makeWrapper ];

  preConfigure = "intltoolize -f";

  configureFlags = [ "--with-controlcenterdir=$(out)/gnome-control-center/keybindings"
                     "--with-dbusservicesdir=$(out)/share/dbus-1/services" ];

  enableParallelBuilding = true;

  preFixup = 
    let
      libPath = stdenv.lib.makeLibraryPath
        [ glib gtk3 clutter pango ];
    in
    ''
      for i in $out/libexec/gpaste/*; do
        wrapProgram $i \
          --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH" \
          --prefix GI_TYPELIB_PATH : "$GI_TYPELIB_PATH"
      done
    '';

  meta = with stdenv.lib; {
    homepage = https://github.com/Keruspe/GPaste;
    description = "Clipboard management system with GNOME3 integration";
    license = licenses.gpl3;
    platforms = platforms.linux;
    maintainers = [ maintainers.lethalman ];
  };
}
