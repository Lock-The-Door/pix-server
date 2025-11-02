# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ pkgs, ... }:

{
  imports = [
    ./services/technitium.nix
    ./services/vikunja.nix
    ./services/vencloud.nix
    ./services/wakapi.nix
    ./services/firefly-iii.nix
  ];

  networking.hostName = "pix"; # Define your hostname.
  # Pick only one of the below networking options.
  networking.networkmanager.enable =
    true; # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "Americas/Toronto";

  i18n.defaultLocale = "en_CA.UTF-8";
  i18n.extraLocales = [ "en_US.UTF-8/UTF-8" ];

  boot.loader.systemd-boot.configurationLimit = 2;
  boot.loader.grub.configurationLimit = 2;

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable sound.
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.jonathan = {
    isNormalUser = true;
    description = "Jonathan";
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    hashedPassword =
      "$y$j9T$a50mifrxV5oU9iX2hRck1/$97yzt0kTnORzQQTbv4bc0SmLWK1YNPB38dzgDcV2e81";
  };
  users.mutableUsers = false;

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [ vim croc git disko nmap ];

  # Nix configuration
  nix.settings = {
    extra-experimental-features = [ "nix-command" "flakes" ];
    accept-flake-config = true;
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:
  services.btrfs.autoScrub.enable = true;
  services.tailscale = {
    enable = true;
    openFirewall = true;
    authKeyFile = "/etc/nixos/auth/tailscale";
    useRoutingFeatures = "server";
    permitCertUid = "caddy";
    extraUpFlags = [ "--advertise-exit-node" "--ssh" "--qr" ];
  };
  fileSystems."/var/lib/tailscale" = {
    depends = [ "/data" ];
    device = "/data/tailscale";
    fsType = "none";
    options = [ "bind" ];
  };
  services.caddy.enable = true;
  networking.nat = {
    enable = true;
    internalInterfaces = [ "ve-+" ];
    externalInterface = "end0";
  };

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.05"; # Did you read the comment?
}
