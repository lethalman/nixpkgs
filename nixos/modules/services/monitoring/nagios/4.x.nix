# Nagios system/network monitoring daemon.
{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.nagios4;

  nagiosUser = "nagios";
  nagiosGroup = "nogroup";

  nagiosState = "/var/lib/nagios";
  nagiosLogDir = "/var/log/nagios";

  nagiosObjectDefs =
    [ <nixos/modules/services/monitoring/nagios/timeperiods.cfg>
      <nixos/modules/services/monitoring/nagios/host-templates.cfg>
      <nixos/modules/services/monitoring/nagios/service-templates.cfg>
      <nixos/modules/services/monitoring/nagios/commands.cfg>
    ] ++ cfg.objectDefs;

  nagiosObjectDefsDir = pkgs.runCommand "nagios-objects" {inherit nagiosObjectDefs;}
    "ensureDir $out; ln -s $nagiosObjectDefs $out/";

  nagiosCfgFile = pkgs.writeText "nagios.cfg"
    ''
      # Paths for state and logs.
      log_file=${nagiosLogDir}/current
      log_archive_path=${nagiosLogDir}/archive
      status_file=${nagiosState}/status.dat
      object_cache_file=${nagiosState}/objects.cache
      temp_file=${nagiosState}/nagios.tmp
      lock_file=/var/run/nagios.lock # Not used I think.
      state_retention_file=${nagiosState}/retention.dat

      # Configuration files.
      #resource_file=resource.cfg
      cfg_dir=${nagiosObjectDefsDir}

      # Uid/gid that the daemon runs under.
      nagios_user=${nagiosUser}
      nagios_group=${nagiosGroup}

      # Misc. options.
      illegal_macro_output_chars=`~$&|'"<>
      retain_state_information=1
    ''; # "

  # Plain configuration for the Nagios web-interface with no
  # authentication.
  nagiosCGICfgFile = pkgs.writeText "nagios.cgi.conf"
    ''
      main_config_file=${cfg.mainConfigFile}
      use_authentication=0
      url_html_path=${cfg.urlPath}
    '';

in

{
  ###### interface

  options = {

    services.nagios4 = {

      enable = mkOption {
        default = false;
        description = "
          Whether to use <link
          xlink:href='http://www.nagios.org/'>Nagios</link> to monitor
          your system or network.
        ";
      };

      objectDefs = mkOption {
        description = "
          A list of Nagios object configuration files that must define
          the hosts, host groups, services and contacts for the
          network that you want Nagios to monitor.
        ";
      };

      plugins = mkOption {
        default = [pkgs.nagiosPluginsOfficial2 pkgs.ssmtp];
        description = "
          Packages to be added to the Nagios <envar>PATH</envar>.
          Typically used to add plugins, but can be anything.
        ";
      };

      mainConfigFile = mkOption {
        default = nagiosCfgFile;
        description = "
          Derivation for the main configuration file of Nagios.
        ";
      };

      cgiConfigFile = mkOption {
        default = nagiosCGICfgFile;
        description = "
          Derivation for the configuration file of Nagios CGI scripts
          that can be used in web servers for running the Nagios web interface.
        ";
      };

      urlPath = mkOption {
        default = "/nagios";
        description = "
          The URL path under which the Nagios web interface appears.
          That is, you can access the Nagios web interface through
          <literal>http://<replaceable>server</replaceable>/<replaceable>urlPath</replaceable></literal>.
        ";
      };

    };

  };


  ###### implementation

  config = mkIf cfg.enable {

    users.extraUsers = singleton
      { name = nagiosUser;
        uid = config.ids.uids.nagios;
        description = "Nagios monitoring daemon";
        home = nagiosState;
      };

    # This isn't needed, it's just so that the user can type "nagiostats
    # -c /etc/nagios.cfg".
    environment.etc = singleton
      { source = cfg.mainConfigFile;
        target = "nagios.cfg";
      };

    environment.systemPackages = [ pkgs.nagios4 ];

    jobs.nagios =
      { description = "Nagios monitoring daemon";

        startOn = "started network-interfaces";
        stopOn = "stopping network-interfaces";

        preStart =
          ''
            mkdir -m 0755 -p ${nagiosState} ${nagiosLogDir} ${nagiosState}/{rw,spool/checkresults}
            chown ${nagiosUser} ${nagiosState} ${nagiosLogDir} ${nagiosState}/{rw,spool/checkresults}
          '';

        script =
          ''
            for i in ${toString config.services.nagios4.plugins}; do
              export PATH=$i/bin:$i/sbin:$i/libexec:$PATH
            done
            exec ${pkgs.nagios4}/bin/nagios ${cfg.mainConfigFile}
          '';
      };

  };

}
