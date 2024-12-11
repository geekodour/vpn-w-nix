{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs"; # keep nixpkgs in sync w hm & the flake
    };
  };
  outputs = inputs@{ nixpkgs, nixpkgs-unstable, home-manager, self, ... }:
    let
      inherit (self) outputs;
      systems = [ "aarch64-linux" "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      overlay-unstable = final: prev: {
        unstable = import inputs.nixpkgs-unstable {
          system = prev.system;
          config = {
            allowUnfreePredicate = (pkg: true);
            allowUnfree = true;
          };
        };
      };
      unstableModule =
        ({ config, pkgs, ... }: { nixpkgs.overlays = [ overlay-unstable ]; });
    in {
      colmena = {
        meta = {
          name = "workloads";
          nixpkgs = import nixpkgs {
            system = "aarch64-linux";
            specialArgs = { inherit nixpkgs-unstable; };
            overlays = [ ];
          };
        };

        foo-vpn = let
          hostName = "foo-vpn";
        in {
          deployment = {
            buildOnTarget = true;
            # NOTE: targetHost here could be the direct public IP address that
            #       the deployer machine(one running this flake) have SSH access
            #       to. I have {hostName} setup as a ssh host in ~/.ssh/config
            #       so I can use the hostname directly.
            #       ssh host example:
            #         Host foo-vpn
            #         HostName <IP from aws ec2/hetzner here>
            #         User root
            #         PubkeyAuthentication yes
            #         PreferredAuthentications publickey
            #         IdentityFile ~/.ssh/id_ed25519
            targetHost = hostName;
            targetUser = "root";
          };

          time.timeZone = "UTC";
          networking.hostName = hostName;
          imports = [
            unstableModule
            home-manager.nixosModules.home-manager
            ./configuration.nix
          ];
        };
      };

      # shell (for dev)
      devShells = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in {
          default = pkgs.mkShell {
            name = "shell";
            packages = [
              pkgs.colmena
            ];
          };
        });
    };
}
