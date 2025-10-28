{
  description = "A flake for Vencloud";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    vencloud.url = "github:Vencord/Vencloud/main";
    vencloud.flake = false;
  };

  outputs = { self, nixpkgs, vencloud }:
    let

      # to work with older version of flakes
      lastModifiedDate =
        self.lastModifiedDate or self.lastModified or "19700101";

      # Generate a user-friendly version number.
      version = builtins.substring 0 8 lastModifiedDate;

      # System types to support.
      supportedSystems =
        [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });

    in {

      # Provide some binary packages for selected system types.
      packages = forAllSystems (system:
        let pkgs = nixpkgsFor.${system};
        in {
          default = pkgs.buildGoModule {
            pname = "vencloud";
            inherit version;
            # In 'nix develop', we don't need a copy of the source tree
            # in the Nix store.
            src = vencloud;

            # This hash locks the dependencies of this package. It is
            # necessary because of how Go requires network access to resolve
            # VCS.  See https://www.tweag.io/blog/2021-03-04-gomod2nix/ for
            # details. Normally one can build with a fake hash and rely on native Go
            # mechanisms to tell you what the hash should be or determine what
            # it should be "out-of-band" with other tooling (eg. gomod2nix).
            # To begin with it is recommended to set this, but one must
            # remember to bump this hash when your dependencies change.
            # vendorHash = pkgs.lib.fakeHash;

            vendorHash = "sha256-4g3mGMhsBaJ4N8SEj56sjAgfH5v8J2RD5c5tMLk5hGU=";
          };
        });

      nixosModules.vencloud = { lib, pkgs, config, ... }:
        let
          inherit (lib)
            mkOption mkIf types mkEnableOption mkPackageOption concatStringsSep;
          cfg = config.services.vencloud;
        in {
          options.services.vencloud = {
            enable = mkEnableOption "vencloud";
            package = mkPackageOption pkgs "vencloud" { };
            redisService = mkOption {
              type = types.str;
              default = "redis.service";
              description = "The name of the systemd redis service vencloud should depend on";
            };

            settings = mkOption {
              type = types.attrsOf types.str;
              default = { };
              description =
                "Settings for the Vencloud server. Refer to <https://github.com/Vencord/Vencloud/blob/main/.env.example>.";
            };

            host = mkOption {
              type = types.str;
              default = "0.0.0.0";
              description = "Host to bind the server to.";
            };
            port = mkOption {
              type = types.int;
              default = 8080;
              description = "Port to bind the server to.";
            };
            redisUri = mkOption {
              type = types.str;
              default = "redis:6379";
              description = "The URI used for connecting to redis";
            };

            rootRedirect = mkOption {
              type = types.str;
              default = "https://github.com/Vencord/Vencloud";
              description = ''
                URL that the root of the API will redirect to.
                              The site specified here HAS TO link to the source code (including your modificiations, if applicable),
                              to comply with the AGPL-3.0 license terms.
                              If your instance is public, you should also provide a Privacy Policy for your users.'';
            };

            sizeLimit = mkOption {
              type = types.int;
              default = 32000000;
              description =
                "The maximum settings backup size in bytes. Default is 32MB.";
            };
            allowedUsers = mkOption {
              type = types.listOf types.int;
              default = [ ];
              description =
                "List of Discord user IDs allowed to use the service, separated by commas. If empty all users are allowed.";
            };
            prometheus = mkOption {
              type = types.bool;
              default = false;
              description =
                "Whether to enable and expose analytics at /metrics";
            };
            proxyHeader = mkOption {
              type = types.str;
              default = "";
              description = ''
                The header containing the connecting user's ip when running behind a reverse proxy,
                              e.g. X-Forwarded-For or CF-Connecting-IP. Used for anti abuse purposes.
                              If not using a reverse proxy, leave this empty'';
            };

            environmentFiles = lib.mkOption {
              type = lib.types.listOf lib.types.path;
              default = [ ];
              example = "/run/secrets/vencloud.env";
              description =
                "Files to load environment variables from. Loaded variables override the nix configuration values. Include discord and pepper variables here.";
            };
          };

          config = mkIf cfg.enable {
            services.vencloud.settings = {
              HOST = cfg.host;
              PORT = toString cfg.port;
              REDIS_URI = cfg.redisUri;
              ROOT_REDIRECT = cfg.rootRedirect;
              SIZE_LIMIT = toString cfg.sizeLimit;
              ALLOWED_USERS =
                concatStringsSep "," (map toString cfg.allowedUsers);
              PROMETHEUS = toString cfg.prometheus;
              PROXY_HEADER = cfg.proxyHeader;
            };

            systemd.services.vencloud = {
              description = "Vencloud Service";
              wantedBy = [ "multi-user.target" ];
              after = [ "network.target" cfg.redisService ];
              requires = [ cfg.redisService ];
              environment = cfg.settings;
              serviceConfig = {
                ExecStart = "${cfg.package}/bin/vencloud";
                EnvironmentFile = cfg.environmentFiles;
                Restart = "always";

                # Basic hardening
                DynamicUser = true;
                KeyringMode = "private";
                ProtectClock = true;
                ProtectHostname = true;
                RestrictNamespaces = true;
                RestrictRealtime = true;
                ProtectKernelModules = true;
                ProtectKernelTunables = true;
                ProtectSystem = "strict";
                PrivateDevices = true;
                PrivateTmp = true;
                PrivateUsers = true;
              };
            };
          };
        };
    };
}
