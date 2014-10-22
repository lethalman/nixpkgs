import ./make-test.nix {
  name = "simple";

  # Do not use "machine", to avoid /tmp/vm-state-machine/ clash with other disks
  nodes.lvmMachine = { config, pkgs, lib, ... }: with lib; {
    # Create a group with a single volume for the root
    boot.initrd.systemd.services.vdaDisk = {
      script = mkForce ''
        if ! lvm pvscan | grep "PV /dev/vda"; then
          dd if=/dev/zero of=/dev/vda bs=512 count=1
          lvm pvcreate /dev/vda
          lvm vgcreate vg /dev/vda
          lvm lvcreate -l 100%VG -n lv vg

          mke2fs -F -t ext4 /dev/vg/lv
        fi
      '';
    };

    fileSystems = mkVMOverride {
      "/" = {
        device = mkVMOverride "/dev/vg/lv";
        systemdInitrdConfig = {
          # Needed only for this test, because vg-lv.device may get triggered by vdaDisk setup
          # before formatting the volume
          requires = [ "vdaDisk.service" ];
          after = [ "vdaDisk.service" ];
        };
      };
    };
    
  };

  testScript =
    ''
      startAll;
      $lvmMachine->waitForUnit("multi-user.target");
      $lvmMachine->shutdown;
    '';
}