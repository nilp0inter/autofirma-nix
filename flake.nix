{
  description = "Un flake para integrar AutoFirma con Nix/NixOS";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs @ {
    self,
    flake-utils,
    nixpkgs,
  }:
    {
      nixosModules.autofirma = import ./nix/module.nix inputs;
    }
    // (flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
        ignoreVulnerable_openssl_1_1 = pkgs.openssl_1_1.overrideAttrs (oldAttrs: rec {
          meta = (oldAttrs.meta or { }) // { knownVulnerabilities = [ ]; };
        });
      in {
        formatter = pkgs.alejandra;
        packages = rec {
          DNIeRemote = pkgs.callPackage ./nix/DNIeRemote/default.nix { openssl_1_1 = ignoreVulnerable_openssl_1_1; };
          autofirma = pkgs.callPackage ./nix/autofirma/default.nix {};
          default = autofirma;
        };
        apps = rec {
          DNIeRemote = flake-utils.lib.mkApp {drv = self.packages.${system}.DNIeRemote;};
          autofirma = flake-utils.lib.mkApp {drv = self.packages.${system}.autofirma;};
          default = autofirma;
        };
      }
    ));
}
