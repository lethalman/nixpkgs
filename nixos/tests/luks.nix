import ./make-test.nix {
  name = "simple";

  machine = { config, pkgs, lib, ... }: with lib; {
    boot.initrd.luks.devices = mkOverride 9 [ { name = "luksroot"; device = "/dev/vda"; } ];
    
    boot.initrd.systemd.services.vdaDisk = {
      script = mkForce ''
        if ! cryptsetup isLuks /dev/vda; then
          echo lukspass > /run/lukskey
          cryptsetup luksFormat /dev/vda /run/lukskey
          cryptsetup luksOpen /dev/vda luksroot --key-file /run/lukskey
          mke2fs -t ext4 /dev/mapper/luksroot
        fi
      '';

      # needed otherwise luksOpen would make luksroot visible to systemd and start
      # fsprobe in parallel before mk2fs
      requiredBy = [ "fsprobe-dev-mapper-luksroot.service" ];
      before = [ "fsprobe-dev-mapper-luksroot.service" ];
    };

    fileSystems = mkVMOverride { "/" = mkVMOverride { device = "/dev/mapper/luksroot"; }; };
    
  };

  testScript =
    ''
      startAll;
      $machine->waitForUnit("multi-user.target");
      $machine->shutdown;
    '';
}
