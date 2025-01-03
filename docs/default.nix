{ pkgs, lib, inputs, ... }:

let
  makeOptionsDoc = configuration: pkgs.nixosOptionsDoc {
    inherit (configuration) options;

    # Filter out any options not beginning with `autofirma-nix`

    transformOptions = option: option // {
      visible = option.visible &&
      builtins.length option.loc > 1 &&
      builtins.elem (builtins.elemAt option.loc 1) [ "autofirma" "dnieremote" "configuradorfnmt" ];
    };
  };

  nixos = makeOptionsDoc
    (lib.nixosSystem {
      inherit (pkgs) system;
      modules = [
        inputs.home-manager.nixosModules.home-manager
        inputs.self.nixosModules.default
      ];
    });

  homeManager = makeOptionsDoc
    (inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        inputs.self.homeManagerModules.default
        {
          home = {
            homeDirectory = "/home/book";
            stateVersion = "24.11";
            username = "book";
          };
        }
      ];
    });

in pkgs.stdenvNoCC.mkDerivation {
  name = "autofirma-nix-book";
  src = ./.;

  patchPhase = ''
    cp ${../README.md} src/README.md

    # mdBook doesn't support this Markdown extension yet
    substituteInPlace **/*.md \
      --replace-quiet '> [!NOTE]' '> **Note**' \
      --replace-quiet '> [!TIP]' '> **Tip**' \
      --replace-quiet '> [!IMPORTANT]' '> **Important**' \
      --replace-quiet '> [!WARNING]' '> **Warning**' \
      --replace-quiet '> [!CAUTION]' '> **Caution**'

    # The "declared by" links point to a file which only exists when the docs
    # are built locally. This removes the links.
    sed '/*Declared by:*/,/^$/d' <${nixos.optionsCommonMark} >>src/nixos_options.md
    sed '/*Declared by:*/,/^$/d' <${homeManager.optionsCommonMark} >>src/home_manager_options.md
  '';

  buildPhase = ''
    ${pkgs.mdbook}/bin/mdbook build --dest-dir $out
  '';
}

