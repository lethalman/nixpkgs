{ stdenv, fetchurl, perl, gd, libpng, zlib }:

stdenv.mkDerivation rec {
  name = "nagios-4.0.6";

  src = fetchurl {
    url = "mirror://sourceforge/nagios/${name}.tar.gz";
    sha1 = "aacd0ebc1a0a91692702667bd98f8a016b59780f";
  };

  buildInputs = [ perl gd libpng zlib ];
  configureFlags = [ "--localstatedir=/var/lib/nagios" ];
  buildFlags = "all";

  # Do not create /var directories
  preInstall = ''
    substituteInPlace Makefile --replace '$(MAKE) install-basic' ""
  '';
  installTargets = "install install-config";

  patches = [ ./nagios.patch ];

  meta = {
    description = "A host, service and network monitoring program";
    homepage = http://www.nagios.org/;
    license = "GPL";
  };
}
