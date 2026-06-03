{
  description = "cgpp's nix-darwin + home-manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
      inputs.darwin.follows = "nix-darwin";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, agenix, disko, ... }:
    let
      darwinSystem = "aarch64-darwin";
      linuxSystem = "x86_64-linux";
      hostname = "Christians-MacBook-Pro";
      codexOverlay = final: _prev: {
        codex = final.callPackage ./pkgs/codex/package.nix { };
      };

      darwinPkgs = import nixpkgs {
        system = darwinSystem;
        config.allowUnfree = true;
        overlays = [ codexOverlay ];
      };

      linuxPkgs = import nixpkgs {
        system = linuxSystem;
        config.allowUnfree = true;
        overlays = [ codexOverlay ];
      };

      mkLinuxScript = name: path: linuxPkgs.writeShellApplication {
        inherit name;
        runtimeInputs = with linuxPkgs; [
          bash
          coreutils
          docker
          findutils
          freerdp
          gawk
          gnugrep
          gnused
          gum
          jq
          nix
          rsync
          util-linux
          xdg-utils
        ];
        text = builtins.readFile path;
      };

      cgppWindows = mkLinuxScript "cgpp-windows" ./scripts/cgpp-windows;
      cgppInstall = mkLinuxScript "cgpp-install" ./scripts/cgpp-install;

      desktopSystem = { enableCaelestia ? true }:
        nixpkgs.lib.nixosSystem {
          system = linuxSystem;
          specialArgs = { inherit inputs; };
          modules = [
            { nixpkgs.overlays = [ codexOverlay ]; }
            ./hosts/desktop/cgpp-t14/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "hm-backup";
                extraSpecialArgs = { inherit inputs enableCaelestia; };
                sharedModules = nixpkgs.lib.optionals enableCaelestia [
                  inputs.caelestia-shell.homeManagerModules.default
                ];
                users = {
                  cgpp = import ./hosts/desktop/cgpp-t14/home.nix;
                  wife = import ./hosts/desktop/cgpp-t14/home-wife.nix;
                };
              };
            }
          ];
        };

      desktopRecoverySystem = { enableCaelestia ? true }:
        nixpkgs.lib.nixosSystem {
          system = linuxSystem;
          specialArgs = { inherit inputs; };
          modules = [
            { nixpkgs.overlays = [ codexOverlay ]; }
            disko.nixosModules.disko
            ./disko/cgpp-t14.nix
            ./hosts/desktop/cgpp-t14/recovery-configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "hm-backup";
                extraSpecialArgs = { inherit inputs enableCaelestia; };
                sharedModules = nixpkgs.lib.optionals enableCaelestia [
                  inputs.caelestia-shell.homeManagerModules.default
                ];
                users = {
                  cgpp = import ./hosts/desktop/cgpp-t14/home.nix;
                  wife = import ./hosts/desktop/cgpp-t14/home-wife.nix;
                };
              };
            }
          ];
        };
    in
    {
      packages.${linuxSystem} = {
        cgpp-windows = cgppWindows;
        cgpp-install = cgppInstall;
        default = cgppInstall;
      };

      apps.${linuxSystem} = {
        cgpp-windows = {
          type = "app";
          program = "${cgppWindows}/bin/cgpp-windows";
        };
        cgpp-install = {
          type = "app";
          program = "${cgppInstall}/bin/cgpp-install";
        };
      };

      darwinConfigurations.${hostname} = nix-darwin.lib.darwinSystem {
        system = darwinSystem;
        specialArgs = { inherit inputs; };
        modules = [
          { nixpkgs.overlays = [ codexOverlay ]; }
          ./hosts/macbook/darwin.nix
          agenix.darwinModules.default
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "hm-backup";
              extraSpecialArgs = { inherit inputs; };
              users.cgpp = import ./hosts/macbook/home.nix;
            };
          }
        ];
      };

      nixosConfigurations.dev = nixpkgs.lib.nixosSystem {
        system = linuxSystem;
        specialArgs = { inherit inputs; };
        modules = [
          { nixpkgs.overlays = [ codexOverlay ]; }
          ./hosts/dev/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "hm-backup";
              users.cgpp = import ./hosts/dev/home.nix;
            };
          }
        ];
      };

      nixosConfigurations.cgpp-t14-nix = desktopSystem { };
      nixosConfigurations.cgpp-t14-nix-lite =
        desktopSystem { enableCaelestia = false; };
      nixosConfigurations.cgpp-t14-recovery = desktopRecoverySystem { };
      nixosConfigurations.cgpp-recovery-iso = nixpkgs.lib.nixosSystem {
        system = linuxSystem;
        specialArgs = { inherit inputs; };
        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-gnome.nix"
          ({ pkgs, ... }: {
            environment.systemPackages = [
              cgppInstall
              cgppWindows
              disko.packages.${linuxSystem}.disko
              pkgs.docker
              pkgs.git
              pkgs.gum
              pkgs.rsync
            ];
            environment.etc."cgpp-recovery".source = ./.;
            image.fileName = "cgpp-recovery.iso";
            nix.settings.experimental-features = [ "nix-command" "flakes" ];
            services.openssh.enable = true;
            users.users.nixos.extraGroups = [ "wheel" "docker" "kvm" "dialout" ];
          })
        ];
      };

      # Convenience alias for rebuild
      # Usage: nix run .#rb
      apps.${darwinSystem}.rb = {
        type = "app";
        program = toString (darwinPkgs.writeShellScript "rb" ''
          darwin-rebuild switch --flake ${self}#${hostname}
        '');
        meta.description = "Rebuild the Darwin host";
      };
    };
}
