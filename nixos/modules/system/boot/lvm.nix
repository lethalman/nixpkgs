{ config, lib, utils, pkgs, ... }:

with lib;
with utils;

let
  cfg = config.boot.initrd.lvm;

  extraUtils = config.system.build.extraUtils;
  
in
{

  options = {

    boot.initrd.lvm = {
      enable = mkOption {
        default = true;
        example = false;
        description = "Whether to enable lvm at boot.";
        type = types.bool;
      };

      config = mkOption {
        default = ''
          global {
            use_lvmetad = 1
          }
        '';
        description = "LVM configuration in initrd.";
        type = types.str;
      };
    };
    
  };

  config = mkIf cfg.enable {

    # copy devicemapper and lvm
    boot.initrd.extraUtilsCommands = ''
      cp -vf ${pkgs.lvm2}/sbin/dmsetup $out/bin/dmsetup
      cp -v ${pkgs.lvm2}/sbin/lvm $out/bin/lvm
      cp -v ${pkgs.lvm2}/sbin/lvmetad $out/bin/lvmetad
      cp -vf ${pkgs.lvm2}/lib/libdevmapper.so.*.* $out/lib
      cp -vf ${pkgs.glibc}/lib/librt.so.* $out/lib
    '';
    
    boot.initrd.extraUtilsCommandsTest = ''
      $out/bin/dmsetup --version 2>&1 | tee -a log | grep "version:"
      LVM_SYSTEM_DIR=$out $out/bin/lvm version 2>&1 | tee -a log | grep "LVM"
      ($out/bin/lvmetad -V || true) | grep lvmetad
    '';

    boot.initrd.extraUdevCommands = ''
      cp -v ${pkgs.lvm2}/lib/udev/rules.d/*.rules $out/
      substituteInPlace $out/69-dm-lvm-metad.rules \
        --replace ${pkgs.lvm2.udev}/bin/systemd-run ${extraUtils}/bin/systemd-run
    '';

    boot.initrd.systemd.sockets.lvmetad = {
      listenStreams = [ "/run/lvm/lvmetad.socket" ];

      wantedBy = [ "sysinit.target"];
      
      socketConfig = {
        SocketMode = "0600";
      };

      # start early
      unitConfig = {
        DefaultDependencies = false;
      };
    };
    
    boot.initrd.systemd.services.lvmetad = {
      description = "LVM2 metadata daemon";
      enable = false;
      wantedBy = [ "sysinit.target" ];
      environment.SD_ACTIVATION = "1";

      requires = [ "lvmetad.socket" ];
      after = [ "lvmetad.socket" ];
      
      # start early
      conflicts = [ "shutdown.target" ];
      unitConfig = {
        DefaultDependencies = false;
      };
      
      serviceConfig = {
        ExecStart = "${extraUtils}/bin/lvmetad -f";
      };
    };

    # Called by udev.
    boot.initrd.systemd.services."lvm2-pvscan@" = {
      description = "LVM2 PV scan on device %i";

      bindsTo = [ "dev-block-%i.device" ];
      requires = [ "lvmetad.socket" ];
      after = [ "lvmetad.socket" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${extraUtils}/bin/lvm pvscan --cache --activate ay %i";
        ExecStop = "${extraUtils}/bin/lvm pvscan --cache %i";
      };
    };

    boot.initrd.extraContents = [
      {
        object = pkgs.writeText "lvm.conf" config.boot.initrd.lvm.config;
        symlink = "/etc/lvm/lvm.conf";
      }
    ];
  };
}
