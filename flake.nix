{
  description = "Config NixOS avec flakes";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
  in {
    nixosConfigurations.manali = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        # configuration.nix importe déjà hardware-configuration.nix
        ./configuration.nix

        # Durcissement & maintenance (ajout non intrusif)
        ({ lib, pkgs, ... }: {
          # Harmonise le nom d’hôte avec l’attribut de flake
          networking.hostName = lib.mkForce "manali";

          # Paquets de base (concaténés à vos paquets existants)
          environment.systemPackages = with pkgs; [
            vim wget curl htop
          ];

          # Trim périodique (SSD)
          services.fstrim.enable = true;

          # Swap mémoire rapide
          zramSwap.enable = true;

          # SSH durci
          services.openssh = {
            enable = true;
            settings = {
              PasswordAuthentication = false;
              KbdInteractiveAuthentication = false;
              PermitRootLogin = "no";
            };
            # Ouvre automatiquement le port si le pare-feu est actif
            openFirewall = true;
          };

          # Désactive l’auto-login GDM (plus sûr)
          services.displayManager.autoLogin.enable = lib.mkForce false;

          # Nix : GC & optimisation
          nix = {
            gc = {
              automatic = true;
              dates = "weekly";
              options = "--delete-older-than 14d";
            };
            optimise.automatic = true;
          };
        })
      ];
    };
  };
}

