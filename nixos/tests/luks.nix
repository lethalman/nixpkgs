import ./make-test.nix {
  name = "simple";

  machine = { config, pkgs, lib, ... }: with lib; {
    boot.initrd.luks.devices = mkOverride 9 [
      { name = "luksroot"; device = "/dev/vda"; keyFile = "/run/lukskey"; }
    ];

    # Create a luks device named luksroot formatted as ext4
    boot.initrd.systemd.services.vdaDisk = {
      script = mkForce ''
        echo lukspass > /run/lukskey-create

        if ! cryptsetup isLuks /dev/vda; then
          cryptsetup luksFormat /dev/vda /run/lukskey-create
        fi
        
        cryptsetup luksOpen /dev/vda luksroot --key-file /run/lukskey-create
        rm -f /run/lukskey-create

        FSTYPE=$(blkid -o value -s TYPE /dev/mapper/luksroot || true)
        if test -z "$FSTYPE"; then
          mke2fs -t ext4 /dev/mapper/luksroot
        fi

        cryptsetup luksClose luksroot
      '';

      # Needed for this test, because luksroot.device gets triggered by luksOpen
      requiredBy = [ "cryptsetup-luksroot.service" ];
      before = [ "cryptsetup-luksroot.service" ];
    };

    # Simulate a crypt key upload
    boot.initrd.systemd.services.cryptKey = {
      requiredBy = [ "cryptsetup-luksroot.service" ];
      before = [ "cryptsetup-luksroot.service" ];

      script = ''
        echo lukspass > /run/lukskey
      '';
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };

    fileSystems = mkVMOverride {
      "/" = {
        device = mkVMOverride "/dev/mapper/luksroot";
        systemdInitrdConfig = {
          # Needed only for this test, because luksroot.device gets triggered by luksOpen in vdaDisk
          requires = [ "cryptsetup-luksroot.service" ];
          after = [ "cryptsetup-luksroot.service" ];
        };
      };
    };
    
  };

  testScript =
    ''
      startAll;
      $machine->waitForUnit("multi-user.target");
      $machine->shutdown;
    '';
}
