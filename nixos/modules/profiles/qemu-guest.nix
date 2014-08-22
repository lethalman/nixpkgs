# Common configuration for virtual machines running under QEMU (using
# virtio).

{ config, pkgs, utils, ... }:

with utils;

{
  boot.initrd.availableKernelModules = [ "virtio_net" "virtio_pci" "virtio_blk" "9p" "9pnet_virtio" ];
  boot.initrd.kernelModules = [ "virtio_balloon" "virtio_console" "virtio_rng" ];

  # Set the system time from the hardware clock to work around a
  # bug in qemu-kvm > 1.5.2 (where the VM clock is initialised
  # to the *boot time* of the host).
  boot.initrd.systemd.services.hwclockBug = {
	  description = "Workaround kvm hwclock bug";
    wantedBy = [ "initrd.target" ];
    before = [ "initrd.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "/bin/hwclock -s";
    };
  };
}
