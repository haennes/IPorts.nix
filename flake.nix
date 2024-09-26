{
  description = "A simple framework for using ports and ips in nix";

  inputs = { nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; };
  outputs = { nixpkgs, ... }: rec {

    nixosConfigurations.host1 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./example/example.nix nixosModules.ports nixosModules.ips ];
    };
    nixosModules = rec {
      ports = import ./ports.nix;
      ips = import ./ips.nix;
      default = import ./both.nix;
    };
  };

}
