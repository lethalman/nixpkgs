{ stdenv, fetchurl, networkmanager, pptp, ppp, intltool, pkgconfig, substituteAll
, withGnome ? true, libsecret-unstable, gnome3, libnm-gtk }:

stdenv.mkDerivation rec {
  name = "${pname}${if withGnome then "-gnome" else ""}-${version}";
  pname = "NetworkManager-pptp";
  version = networkmanager.version;

  src = fetchurl {
    url = "mirror://gnome/sources/${pname}/1.0/${pname}-${version}.tar.xz";
    sha256 = "0xpflw6vp1ahvpz7mnnldqvk455wz2j7dahd9lxqs95frmjmq390";
  };

  buildInputs = [ networkmanager pptp ppp ]
    ++ stdenv.lib.optionals withGnome [ libsecret-unstable libnm-gtk gnome3.gtk gnome3.libgnome_keyring ];

  nativeBuildInputs = [ intltool pkgconfig ];

  configureFlags =
    if withGnome then "--with-gnome --with-gtkver=3" else "--without-gnome";

  postConfigure = "sed 's/-Werror//g' -i Makefile */Makefile";

  patches =
    [ ( substituteAll {
        src = ./pptp-purity.patch;
        inherit ppp pptp;
      })
    ];

  meta = {
    description = "PPtP plugin for NetworkManager";
    inherit (networkmanager.meta) maintainers platforms;
  };
}
