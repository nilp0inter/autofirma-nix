{
  description = "Un flake para integrar AutoFirma con Nix/NixOS";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs @ {
    self,
    flake-parts,
    nixpkgs,
  }:
  flake-parts.lib.mkFlake { inherit inputs; } {
    flake = {
      nixosModules.autofirma = import ./nix/module.nix inputs;
      packages.x86_64-linux = let
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
      in
      {
        libpkcs11-dnie = pkgs.callPackage ./nix/libpkcs11-dnie/default.nix { };
        libpkcs11-fnmtdnie = pkgs.callPackage ./nix/libpkcs11-fnmtdnie/default.nix { };
      };
    };
    systems = [
      "x86_64-linux"
      # "i686-linux"
    ];
    perSystem = { config, system, ... }: let
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
    };
  };
}
