{ ... }: {
  services.caddy.virtualHosts."pix.pug-squeaker.ts.net:8024" = {
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
      networking.firewall.allowedTCPPorts = [ 8080 ];

      services.firefly-iii = {
        enable = true;
        dataDir = "/var/lib/firefly-iii/app";
        user = "firefly-iii";
        group = "firefly-iii";
        settings = {
          APP_ENV = "production";
          APP_URL = "https://pix.pug-squeaker.ts.net:8024";
          APP_KEY_FILE = "/var/secrets/firefly-iii";
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
        };
      };
      services.firefly-iii-data-importer = {
        enable = true;
        dataDir = "/var/lib/firefly-iii/importer";
        user = "firefly-iii";
        group = "firefly-iii";
        settings = { FIREFLY_III_URL = "http://localhost:8080"; };
      };
      systemd.services.firefly-iii-data-importer.serviceConfig.StateDirectory =
        "firefly-iii";

      system.stateVersion = "25.05";
    };

    bindMounts = {
      "/run/secrets/firefly-iii:idmap" = {
        hostPath = "/etc/nixos/auth/firefly-iii";
      };
      "/var/lib/private/firefly-iii:idmap" = {
        hostPath = "/data/firefly-iii";
        isReadOnly = false;
      };
    };
  };
}
