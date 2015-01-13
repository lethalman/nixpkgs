{ stdenv, fetchurl, glib, dbus_libs, unzip, automake, libtool, autoconf, m4, docbook_xsl,
  intltool, gtk_doc, gobjectIntrospection, pkgconfig, libxslt, libgcrypt }:

stdenv.mkDerivation rec {
  version = "0.18";
  name = "libsecret-unstable-${version}";

  src = fetchurl {
    url = "https://git.gnome.org/browse/libsecret/snapshot/libsecret-${version}.zip";
    sha256 = "1r1wmvqds29wx4pw28qbdlzj1l5w8vbqv83jihh08lhgnznvjj2a";
  };

  propagatedBuildInputs = [ glib dbus_libs ];
  nativeBuildInputs = [ unzip ];
  buildInputs = [ gtk_doc automake libtool autoconf intltool gobjectIntrospection pkgconfig libxslt libgcrypt m4 docbook_xsl ];

  configureScript = "./autogen.sh";

  meta = {
    inherit (glib.meta) platforms maintainers;
  };
}
