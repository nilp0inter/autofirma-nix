{
  description = "Un flake para integrar AutoFirma con Nix/NixOS";

  nixConfig = {
    extra-substituters = [
      "https://autofirma-nix.cachix.org"
    ];
    extra-trusted-public-keys = [
      "autofirma-nix.cachix.org-1:cDC9Dtee+HJ7QZcM8s36836scXyRToqNX/T+yvjiI0E="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-24.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs @ {
    self,
    flake-parts,
    nixpkgs,
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      flake = {
        homeManagerModules = rec {
          autofirma = import ./nix/autofirma/hm-module.nix inputs;
          dnieremote = import ./nix/dnieremote/hm-module.nix inputs;
          configuradorfnmt = import ./nix/configuradorfnmt/hm-module.nix inputs;
          default = {
            imports = [
              autofirma
              dnieremote
              configuradorfnmt
            ];
          };
        };
        nixosModules = rec {
          autofirma = import ./nix/autofirma/module.nix inputs;
          dnieremote = import ./nix/dnieremote/module.nix inputs;
          configuradorfnmt = import ./nix/configuradorfnmt/module.nix inputs;
          default = {
            imports = [
              autofirma
              dnieremote
              configuradorfnmt
            ];
          };
        };
        packages.x86_64-linux = let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          ignoreVulnerable_openssl_1_1 = pkgs.openssl_1_1.overrideAttrs (oldAttrs: rec {
            meta = (oldAttrs.meta or {}) // {knownVulnerabilities = [];};
          });
        in {
          dnieremote = pkgs.callPackage ./nix/dnieremote/default.nix {openssl_1_1 = ignoreVulnerable_openssl_1_1;};
          configuradorfnmt = pkgs.callPackage ./nix/configuradorfnmt/default.nix {};
        };
      };
      systems = [
        "x86_64-linux"
        "i686-linux"
      ];
      perSystem = {
        config,
        system,
        self',
        ...
      }: let
        pkgs = nixpkgs.legacyPackages.${system};
        pom-tools = {
          update-java-version = pkgs.callPackage ./nix/pom-tools/update-java-version.nix {};
          update-pkg-version = pkgs.callPackage ./nix/pom-tools/update-pkg-version.nix {};
          update-dependency-version-by-groupId = pkgs.callPackage ./nix/pom-tools/update-dependency-version-by-groupId.nix {};
          remove-module-on-profile = pkgs.callPackage ./nix/pom-tools/remove-module-on-profile.nix {};
          reset-project-build-timestamp = pkgs.callPackage ./nix/pom-tools/reset-project-build-timestamp.nix {};
          reset-maven-metadata-local-timestamp = pkgs.callPackage ./nix/pom-tools/reset-maven-metadata-local-timestamp.nix {};
        };
      in {
        formatter = pkgs.alejandra;
        packages = rec {
          jmulticard = pkgs.callPackage ./nix/autofirma/dependencies/jmulticard {
            inherit pom-tools;

            src-rev = "v1.8";
            src-hash = "sha256-sCqMK4FvwRHsGIB6iQVyqrx0+EDiUfQSAsPqmDq2Giw=";

            maven-dependencies-hash = "sha256-qI6gYbGKTQ4Q4tV8NI37TSd3eQTyHHgndUGS943UvNU=";
          };
          clienteafirma-external = pkgs.callPackage ./nix/autofirma/dependencies/clienteafirma-external {
            inherit pom-tools;

            src-rev = "OT_14395";
            src-hash = "sha256-iS3I6zIxuKG133s/FqDlXZzOZ2ZOJcqZK9X6Tv3+3lc=";

            maven-dependencies-hash = "sha256-N2lFeRM/eu/tMFTCQRYSHYrbXNgbAv49S7qTaUmb2+Q=";
          };
          autofirma = pkgs.callPackage ./nix/autofirma/default.nix {
            inherit jmulticard clienteafirma-external pom-tools;

            src-rev = "v1.8.3";
            src-hash = "sha256-GQyj3QuWIHTkYwdJ4oKVsG923YG9mCUXfhqdIvEWNMA=";

            maven-dependencies-hash = "sha256-zPWjBu1YtN0U9+wy/WG0NWg1EsO3MD0nhnkUsV7h6Ew=";
          };
          default = self'.packages.autofirma;
        };
        checks = {
          autofirma-sign = pkgs.runCommand "autofirma-sign" {} ''
            mkdir -p $out
            echo "NixOS AutoFirma Sign Test" > document.txt

            ${inputs.nixpkgs.lib.getExe pkgs.openssl} req -x509 -newkey rsa:2048 -keyout private.key -out certificate.crt -days 365 -nodes -subj "/C=ES/O=TEST AUTOFIRMA NIX/OU=DNIE/CN=AC DNIE 004" -passout pass:1234
            ${inputs.nixpkgs.lib.getExe pkgs.openssl} pkcs12 -export -out certificate.p12 -inkey private.key -in certificate.crt -name "testcert" -password pass:1234

            ${inputs.nixpkgs.lib.getExe self'.packages.autofirma} sign -store pkcs12:certificate.p12 -i document.txt -o document.txt.sign -filter alias.contains=testcert -password 1234 -xml
          '';
        };
      };
    };
}
