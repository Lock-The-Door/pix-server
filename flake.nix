{
  description = "My NixOS Server Configuration for a Raspberry Pi 5";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.11";
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    vencloud.url = "path:./pkgs/vencloud";
    vencloud.inputs.nixpkgs.follows = "nixpkgs";
  };

  # Optional: Binary cache for the flake
  nixConfig = {
    extra-substituters = [ "https://nixos-raspberrypi.cachix.org" ];
    extra-trusted-public-keys = [
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
  };

  outputs = { nixpkgs, disko, nixos-raspberrypi, vencloud, ... }@inputs: {
    nixosConfigurations = {
      pix = nixos-raspberrypi.lib.nixosSystemFull {
        specialArgs = inputs;
        modules = [
          ({ nixos-raspberrypi, ... }: {
            imports = with nixos-raspberrypi.nixosModules; [
              # Hardware configuration
              raspberry-pi-5.base
              raspberry-pi-5.page-size-16k
              raspberry-pi-5.bluetooth
            ];
            boot.loader.raspberryPi.bootloader = "kernel";
          })

          ./configuration.nix
          disko.nixosModules.disko
          ./disko-config.nix
        ];
      };
      pix-x86 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hardware-configuration.nix
          ./configuration.nix
          disko.nixosModules.disko
          ./disko-config-efi.nix

          ({ pkgs, ... }: {
            # Use the systemd-boot EFI boot loader.
            boot.loader = {
              efi = {
                # canTouchEfiVariables = true;
                efiSysMountPoint = "/boot/EFI";
              };
              systemd-boot = {
                enable = true;
                editor = false;
              };
              grub.enable = false;
              timeout = 2;
            };

            # Use latest kernel.
            boot.kernelPackages = pkgs.linuxPackages_latest;
          })
        ];
      };
    };
  };
}
