let fireflyUrl = "https://pix.pug-squeaker.ts.net:8024";
in { pkgs, ... }: {
  services.caddy.virtualHosts."pix.pug-squeaker.ts.net:8024" = {
    extraConfig = "reverse_proxy 192.168.103.100:80";
  };
  services.caddy.virtualHosts."pix.pug-squeaker.ts.net:8025" = {
    extraConfig = "reverse_proxy 192.168.103.100:8080";
  };
  networking.firewall.allowedTCPPorts = [ 8024 ];

  containers.firefly-iii = {
    # Default container options
    autoStart = true;
    ephemeral = true;
    privateNetwork = true;
    privateUsers = "pick";

    hostAddress = "192.168.103.10";
    localAddress = "192.168.103.100";

    config = { ... }: {
      networking.firewall.allowedTCPPorts = [ 80 ];

      services.caddy = {
        enable = true;
        group = "firefly-iii";
        globalConfig = ''
          servers {
          	trusted_proxies static private_ranges
          }
        '';
        extraConfig = ''
          :80 {
           	root * ${pkgs.firefly-iii}/public
            php_fastcgi unix//run/phpfpm/firefly-iii.sock {
              capture_stderr
            }
            file_server
          }
        '';
      };

      services.firefly-iii = {
        enable = true;
        settings = {
          APP_ENV = "production";
          APP_URL = fireflyUrl;
          APP_KEY_FILE = "/run/secrets/firefly-iii";
          TZ = "America/Toronto";
          COOKIE_DOMAIN = "https://pix.pug-squeaker.ts.net:8024";
          COOKIE_SECURE = "true";
          ENABLE_EXTERNAL_MAP = "true";
          ENABLE_EXCHANGE_RATES = "true";
          ENABLE_EXTERNAL_RATES = "true";
          MAP_DEFAULT_LAT = "43.6425";
          MAP_DEFAULT_LONG = "-79.387222";
          MAP_DEFAULT_ZOOM = "6";
          VALID_URL_PROTOCOLS = "http, https, mailto";
          TRUSTED_PROXIES = "*";
        };
      };
      systemd.services.firefly-iii.serviceConfig.StateDirectory =
        "firefly-iii/app";
      services.firefly-iii-data-importer = {
        enable = false;
        # group = "firefly-iii";
        settings = { FIREFLY_III_URL = fireflyUrl; };
      };
      systemd.services.firefly-iii-data-importer.serviceConfig.StateDirectory =
        "firefly-iii/importer";


      fileSystems."/var/lib/firefly-iii/storage/database" = {
        depends = [ "/run/firefly-iii-data" ];
        device = "/run/firefly-iii-data/database";
        fsType = "none";
        options = [ "bind" ];
      };
      fileSystems."/var/lib/firefly-iii/storage/upload" = {
        depends = [ "/run/firefly-iii-data" ];
        device = "/run/firefly-iii-data/upload";
        fsType = "none";
        options = [ "bind" ];
      };
      systemd.tmpfiles.rules = [
        "d /run/firefly-iii-data/database 0700 firefly-iii firefly-iii"
        "d /run/firefly-iii-data/upload 0700 firefly-iii firefly-iii"
      ]

      system.stateVersion = "25.05";
    };

    bindMounts = {
      "/run/secrets/firefly-iii:idmap" = {
        hostPath = "/etc/nixos/auth/firefly-iii";
      };
      "/run/firefly-iii-data:idmap" = {
        hostPath = "/data/firefly-iii";
        isReadOnly = false;
      };
    };
  };
}
