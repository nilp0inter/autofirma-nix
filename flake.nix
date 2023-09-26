{
  description = "Un flake para integrar AutoFirma con Nix/NixOS";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs @ { self, flake-utils, nixpkgs }:
    {
      nixosModules.autofirma = import ./nix/module.nix inputs;
    } //
    (flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system}; in
      {
        formatter = pkgs.alejandra;
        packages = rec{
          autofirma = pkgs.callPackage ./nix/autofirma/default.nix {};
          default = autofirma;
        };
        apps = rec {
          autofirma = flake-utils.lib.mkApp { drv = self.packages.${system}.autofirma; };
          default = autofirma;
        };
      }
    ));
}
