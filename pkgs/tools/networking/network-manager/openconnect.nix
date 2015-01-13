{ stdenv, fetchurl, openconnect, intltool, pkgconfig, networkmanager
, withGnome ? true, libsecret-unstable, gnome3, procps, module_init_tools, libnm-gtk }:

stdenv.mkDerivation rec {
  name = "${pname}${if withGnome then "-gnome" else ""}-${version}";
  pname = "NetworkManager-openconnect";
  version = networkmanager.version;

  src = fetchurl {
    url = "mirror://gnome/sources/${pname}/1.0/${pname}-${version}.tar.xz";
    sha256 = "0przs8hzvb6wrf4gc0p9063x67qp9503396aknqq5f79xzw25wq6";
  };

  buildInputs = [ openconnect networkmanager ]
    ++ stdenv.lib.optionals withGnome [ libsecret-unstable libnm-gtk gnome3.gtk gnome3.libgnome_keyring gnome3.gconf ];

  nativeBuildInputs = [ intltool pkgconfig ];

  configureFlags = [
    "${if withGnome then "--with-gnome --with-gtkver=3" else "--without-gnome"}"
    "--disable-static"
  ];

  preConfigure = ''
     substituteInPlace "configure" \
       --replace "/sbin/sysctl" "${procps}/sbin/sysctl"
     substituteInPlace "src/nm-openconnect-service.c" \
       --replace "/usr/sbin/openconnect" "${openconnect}/sbin/openconnect" \
       --replace "/sbin/modprobe" "${module_init_tools}/sbin/modprobe"
  '';

  postConfigure = ''
     substituteInPlace "./auth-dialog/Makefile" \
       --replace "-Wstrict-prototypes" "" \
       --replace "-Werror" ""
     substituteInPlace "properties/Makefile" \
       --replace "-Wstrict-prototypes" "" \
       --replace "-Werror" ""
  '';

  meta = {
    description = "NetworkManager's OpenConnect plugin";
    inherit (networkmanager.meta) maintainers platforms;
  };
}

