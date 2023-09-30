inputs: {
  pkgs,
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.programs.autofirma;
  inherit (pkgs.stdenv.hostPlatform) system;
in {
  options.programs.autofirma = {
    enable = mkEnableOption "Autofirma";
    package = mkPackageOptionMD inputs.self.packages.${system} "autofirma" {};
    finalPackage = mkOption {
      type = types.package;
      readOnly = true;
      default = cfg.package.override {
        firefox = config.programs.firefox.package;
      };
      defaultText =
        literalExpression
        "`programs.autofirma.package` with applied configuration";
      description = mdDoc ''
        The Autofirma package after applying configuration.
      '';
    };

    firefoxIntegration.profiles = mkOption {
      type = types.attrsOf (types.submodule ({ config, name, ... }: {
        options = {
          name = mkOption {
            type = types.str;
            default = name;
            description = "Profile name.";
          };

          enable = mkEnableOption "Enable Autofirma in this firefox profile.";
        };
      }));
    };
  };
  config = mkIf cfg.enable {
    home.packages = [cfg.finalPackage];
    programs.firefox.profiles = flip mapAttrs cfg.firefoxIntegration.profiles (name: { enable, ... }: {
      settings = mkIf enable {
        "network.protocol-handler.app.afirma" = "${cfg.package}/bin/autofirma";
        "network.protocol-handler.warn-external.afirma" = false;
        "network.protocol-handler.external.afirma" = true;
      };
    });
  };
}
