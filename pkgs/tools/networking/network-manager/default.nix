{ stdenv, fetchurl, intltool, wirelesstools, pkgconfig, dbus_glib, xz
, udev, libnl, libuuid, polkit, gnutls, ppp, dhcp, dhcpcd, iptables
, libgcrypt, dnsmasq, avahi, bind, perl, bluez5, substituteAll
, gobjectIntrospection, modemmanager, openresolv, ncurses, readline, iputils, libndp, newt }:

stdenv.mkDerivation rec {
  name = "network-manager-${version}";
  version = "1.0.0";

  src = fetchurl {
    url = "mirror://gnome/sources/NetworkManager/1.0/NetworkManager-${version}.tar.xz";
    sha256 = "0isrv1875whysnrf3fd1cz96xwd54nvj1rijk3fmx5qccznayris";
  };

  preConfigure = ''
    substituteInPlace tools/glib-mkenums --replace /usr/bin/perl ${perl}/bin/perl
    configureFlagsArray+=(
      "--with-udev-dir=$out/lib/udev"
      "--with-dbus-sys-dir=$out/etc/dbus-1/system.d"
      "--with-pppd-plugin-dir=$out/lib/pppd/${ppp.version}"
    )
  '';

  # Right now we hardcode quite a few paths at build time. Probably we should
  # patch networkmanager to allow passing these path in config file. This will
  # remove unneeded build-time dependencies.
  configureFlags = [
    "--with-distro=exherbo"
    "--with-dhclient=${dhcp}/sbin/dhclient"
    # Upstream prefers dhclient, so don't add dhcpcd to the closure
    #"--with-dhcpcd=${dhcpcd}/sbin/dhcpcd"
    "--with-dhcpcd=no"
    "--with-iptables=${iptables}/sbin/iptables"
    "--with-resolvconf=${openresolv}/sbin/resolvconf"
    "--sysconfdir=/etc" "--localstatedir=/var"
    "--with-crypto=gnutls" "--disable-more-warnings"
    "--with-systemdsystemunitdir=$(out)/etc/systemd/system"
    "--with-kernel-firmware-dir=/run/current-system/firmware"
    "--with-session-tracking=systemd"
    "--with-modem-manager-1"
    "--with-pppd=${ppp}/bin/pppd"
    "--with-dnsmasq=${dnsmasq}/bin/dnsmasq"
    "--with-nmtui"
  ];

  buildInputs = [
    wirelesstools udev libnl libuuid polkit ppp xz bluez5 gobjectIntrospection
    modemmanager readline libndp newt
  ];

  propagatedBuildInputs = [ dbus_glib gnutls libgcrypt ];

  nativeBuildInputs = [ intltool pkgconfig ];

  # TODO(cstrahan): should we patch out parts of NM_PATHS_DEFAULT for purity?
  # TODO(cstrahan): look for more instances of `nm_utils_find_helper` to find
  # packages we might want to include.
  patches =
    [ ( substituteAll {
        src = ./nixos-purity.patch;
        inherit avahi dnsmasq ppp bind iputils;
        glibc = stdenv.cc.libc;
      })
      ./unmanage_virtual.patch
    ];

  preInstall =
    ''
      installFlagsArray=( "sysconfdir=$out/etc" "localstatedir=$out/var" )
    '';

  postInstall =
    ''
      mkdir -p $out/lib/NetworkManager

      # FIXME: Workaround until NixOS' dbus+systemd supports at_console policy
      substituteInPlace $out/etc/dbus-1/system.d/org.freedesktop.NetworkManager.conf --replace 'at_console="true"' 'group="networkmanager"'

      # rename to network-manager to be in style
      mv $out/etc/systemd/system/NetworkManager.service $out/etc/systemd/system/network-manager.service

      # systemd in NixOS doesn't use `systemctl enable`, so we need to establish
      # aliases ourselves.
      ln -s $out/etc/systemd/system/NetworkManager-dispatcher.service $out/etc/systemd/system/dbus-org.freedesktop.nm-dispatcher.service
      ln -s $out/etc/systemd/system/network-manager.service $out/etc/systemd/system/dbus-org.freedesktop.NetworkManager.service

      # fix readline in libtool file, avoid putting it in propagated build inputs
      for lib in $out/lib/*.la; do
        substituteInPlace $lib --replace "-lreadline" "-L${readline}/lib -lreadline"
      done
    '';

  meta = with stdenv.lib; {
    homepage = http://projects.gnome.org/NetworkManager/;
    description = "Network configuration and management tool";
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [ phreedom urkud rickynils iElectric ];
    platforms = platforms.linux;
  };
}
