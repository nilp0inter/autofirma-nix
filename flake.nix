{
  description = "A Nix flake for AutoFirma and related Spanish e-signature tools.";

  nixConfig = {
    extra-substituters = [
      "https://autofirma-nix.cachix.org"
    ];
    extra-trusted-public-keys = [
      "autofirma-nix.cachix.org-1:cDC9Dtee+HJ7QZcM8s36836scXyRToqNX/T+yvjiI0E="
    ];
  };

  # Common inputs
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  # Autofirma sources
  inputs = {
    jmulticard-src = {
      url = "github:ctt-gob-es/jmulticard/v1.8";
      flake = false;
    };

    clienteafirma-external-src = {
      url = "github:ctt-gob-es/clienteafirma-external/OT_14395";
      flake = false;
    };

    autofirma-src = {
      url = "github:ctt-gob-es/clienteafirma/v1.8.3";
      flake = false;
    };
  };

  outputs = inputs @ {
    self,
    flake-parts,
    nixpkgs,
    jmulticard-src,
    clienteafirma-external-src,
    autofirma-src,
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
      in {
        formatter = pkgs.alejandra;
        packages = rec {
          pom-tools = pkgs.callPackage ./nix/pom-tools {};
          autofirma-truststore = pkgs.callPackage ./nix/autofirma/truststore { };
          jmulticard = pkgs.callPackage ./nix/autofirma/dependencies/jmulticard {
            inherit pom-tools;

            src = jmulticard-src;

            maven-dependencies-hash = "sha256-qI6gYbGKTQ4Q4tV8NI37TSd3eQTyHHgndUGS943UvNU=";
          };
          clienteafirma-external = pkgs.callPackage ./nix/autofirma/dependencies/clienteafirma-external {
            inherit pom-tools;

            src = clienteafirma-external-src;

            maven-dependencies-hash = "sha256-N2lFeRM/eu/tMFTCQRYSHYrbXNgbAv49S7qTaUmb2+Q=";
          };
          autofirma = pkgs.callPackage ./nix/autofirma/default.nix {
            inherit jmulticard clienteafirma-external pom-tools autofirma-truststore;

            src = autofirma-src;

            maven-dependencies-hash = "sha256-zPWjBu1YtN0U9+wy/WG0NWg1EsO3MD0nhnkUsV7h6Ew=";
          };
          default = self'.packages.autofirma;
        };
        checks = let
          openssl = inputs.nixpkgs.lib.getExe pkgs.openssl;
          autofirma = inputs.nixpkgs.lib.getExe self'.packages.autofirma;
          curl = inputs.nixpkgs.lib.getExe pkgs.curl;
          xmlstarlet = inputs.nixpkgs.lib.getExe pkgs.xmlstarlet;
        in {
          autofirma-sign = pkgs.runCommand "autofirma-sign" {} ''
            mkdir -p $out
            echo "NixOS AutoFirma Sign Test" > document.txt

            ${openssl} req -x509 -newkey rsa:2048 -keyout private.key -out certificate.crt -days 365 -nodes -subj "/C=ES/O=TEST AUTOFIRMA NIX/OU=DNIE/CN=AC DNIE 004" -passout pass:1234
            ${openssl} pkcs12 -export -out certificate.p12 -inkey private.key -in certificate.crt -name "testcert" -password pass:1234

            ${autofirma} sign -store pkcs12:certificate.p12 -i document.txt -o document.txt.sign -filter alias.contains=testcert -password 1234 -xml
          '';
          # truststore-members = pkgs.runCommand "truststore-members" {} ''
          #   mkdir -p $out

          #   ${curl} -s --output $out/Prestadores.xml https://sedeaplicaciones.minetur.gob.es/PrestadoresDatosAbiertos/Prestadores.xml
          #   ${xmlstarlet} sel -t -m '/PRESTADORES/PRESTADOR/SERVICIOS/SERVICIO/Clasificacion[text() = "Sede cualificado"]/../../../NombreSocial/text()' -c . -n $out/Prestadores.xml | sort | uniq > $out/cifs_prestadores_sede.txt

          # '';
        };
      };
    };
}
