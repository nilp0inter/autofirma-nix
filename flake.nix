{
  description = "Un flake para integrar AutoFirma con Nix/NixOS";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, flake-utils, nixpkgs }: 
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system}; in
      {
        packages = rec{
          autofirma = pkgs.callPackage ./autofirma.nix {};
          default = autofirma;
        };
        apps = rec {
          autofirma = flake-utils.lib.mkApp { drv = self.packages.${system}.autofirma; };
          default = autofirma;
        };
      }
    );
}
