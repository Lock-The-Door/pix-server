
sudo git pull
sudo nix-env -p /nix/var/nix/profiles/system --delete-generations old
sudo nixos-rebuild switch
