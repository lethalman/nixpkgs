{ config, lib, pkgs, ... }:

with lib;

{

  ###### generic interface for bootloaders

  options = {

    boot.loader = {

      timeout = mkOption {
        default = 5;
        type = types.int;
        description = ''
          Timeout (in seconds) until the loader boots the default menu item.
        '';
      };

    };

  };

}
