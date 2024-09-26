{
  description = "A simple framework for using ports, ips and macs in nix";

  inputs = { nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; };
  outputs = { nixpkgs, ... }: rec {

    nixosConfigurations.host1 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./example/example.nix nixosModules.default ];
    };
    nixosModules = rec {
      ports = import ./ports.nix;
      ips = import ./ips.nix;
      macs = import ./macs.nix;
      default = { imports = [ ports ips macs ]; };
    };
  };

}
