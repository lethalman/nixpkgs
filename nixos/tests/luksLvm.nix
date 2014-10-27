# The interactive version will ask for the passphrase (lukspass),
# instead of using keyfiles.
#
# Test it with:
# nix-build nixos/tests/luks.nix -A driver --arg interactive true
# result/bin/nixos-run-vms

{ interactive ? false, ... }@args:

import ./make-test.nix {
  name = "simple";

  # Do not use "machine", to avoid /tmp/vm-state-machine/ clash with other disks
  nodes.luksLVMMachine = { config, pkgs, lib, ... }: with lib; {
    boot.initrd.luks.devices = mkOverride 9 [
      ({ name = "luksroot"; device = "/dev/vda"; } // (optionalAttrs (!interactive) { keyFile = "/run/lukskey"; }))
    ];

    # Create a luks device named luksroot formatted as ext4
    boot.initrd.systemd.services.vdaDisk = {
      enable = false;
      script = mkForce ''
        echo lukspass > /run/lukskey-create

        if ! cryptsetup isLuks /dev/vda; then
          dd if=/dev/zero of=/dev/vda bs=512 count=1
          cryptsetup luksFormat /dev/vda /run/lukskey-create
          # Support both keyfile and passphrase for interactive test
          cryptsetup luksOpen /dev/vda luksroot --key-file /run/lukskey-create
          echo lukspass|cryptsetup luksAddKey /dev/vda -d /run/lukskey-create
          rm -f /run/lukskey-create
        fi

        # LVM on luksroot
        if ! lvm pvscan | grep "PV /dev/mapper/luksroot"; then
          dd if=/dev/zero of=/dev/mapper/luksroot bs=512 count=1
          lvm pvcreate /dev/mapper/luksroot
          lvm vgcreate vg /dev/mapper/luksroot
          lvm lvcreate -l 100%VG -n lv vg
        fi

        lvm vgchange -a y vg
        FSTYPE=$(blkid -o value -s TYPE /dev/mapper/vg-lv || true)
        if test -z "$FSTYPE"; then
          echo FORMATTING > /dev/kmsg
          mke2fs -t ext4 /dev/mapper/vg-lv
          echo FORMATTED > /dev/kmsg
        fi
        lvm vgchange -a n vg

        cryptsetup luksClose luksroot
      '';

      # Needed only for this test
      requiredBy = [ "cryptsetup-luksroot.service" ];
      before = [ "cryptsetup-luksroot.service" ];
    };

    # Simulate a crypt key upload
    boot.initrd.systemd.services.cryptKey = {
      script = ''
        echo lukspass > /run/lukskey
      '';

      requiredBy = [ "cryptsetup-luksroot.service" ];
      before = [ "cryptsetup-luksroot.service" ];
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };

    boot.initrd.systemd.services.boh = {
      script = ''
        sleep 1
      '';

      requires = [ "cryptsetup-luksroot.service" ];
      after = [ "cryptsetup-luksroot.service" ];
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };

    fileSystems = mkVMOverride {
      "/" = {
        device = mkVMOverride "/dev/mapper/vg-lv";
        systemdInitrdConfig = {
          # Needed only for this test
          requires = [ "cryptsetup-luksroot.service" ];
          after = [ "cryptsetup-luksroot.service" ];
        };
      };
    };
    
  };

  testScript =
    ''
      startAll;
      $luksMachine->waitForUnit("multi-user.target");
      $luksMachine->shutdown;
    '';
} args