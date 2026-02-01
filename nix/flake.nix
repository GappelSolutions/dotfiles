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
    };
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, agenix }:
    let
      system = "aarch64-darwin";
      hostname = "cgpp-mac"; # change this to your hostname

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      darwinConfigurations.${hostname} = nix-darwin.lib.darwinSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./darwin-configuration.nix
          agenix.darwinModules.default
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";
              extraSpecialArgs = { inherit inputs; };
              users.cgpp = import ./home.nix;
            };
          }
        ];
      };

      # Convenience alias for rebuild
      # Usage: nix run .#rebuild
      apps.${system}.rebuild = {
        type = "app";
        program = toString (pkgs.writeShellScript "rebuild" ''
          darwin-rebuild switch --flake ${self}#${hostname}
        '');
      };
    };
}
