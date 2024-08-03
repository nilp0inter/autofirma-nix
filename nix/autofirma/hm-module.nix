inputs: {
  pkgs,
  osConfig,
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.programs.autofirma;
  inherit (pkgs.stdenv.hostPlatform) system;
in {
  options.programs.autofirma.truststore = {
    package = mkPackageOption inputs.self.packages.${system} "autofirma-truststore" {};
    enableGlobalAutoFirmaCAs = mkEnableOption "Add AutoFirma CAs to the system-wide trusted root certificates list";
    finalPackage = mkOption {
      type = types.package;
      readOnly = true;
      default = cfg.truststore.package;
      defaultText =
        literalExpression
        "`programs.autofirma.truststore.package` with applied configuration";
      description = mdDoc ''
        The AutoFirma truststore package after applying configuration.
      '';
    };
  };
  options.programs.autofirma = {
    enable = mkEnableOption "AutoFirma";
    package = mkPackageOption inputs.self.packages.${system} "autofirma" {};
    finalPackage = mkOption {
      type = types.package;
      readOnly = true;
      default = cfg.package.override {
        autofirma-truststore = cfg.truststore.finalPackage;
        firefox = config.programs.firefox.package;
      };
      defaultText =
        literalExpression
        "`programs.autofirma.package` with applied configuration";
      description = mdDoc ''
        The AutoFirma package after applying configuration.
      '';
    };

    firefoxIntegration.profiles = mkOption {
      type = types.attrsOf (types.submodule ({
        config,
        name,
        ...
      }: {
        options = {
          name = mkOption {
            type = types.str;
            default = name;
            description = "Profile name.";
          };

          enable = mkEnableOption "Enable AutoFirma in this firefox profile.";
        };
      }));
    };
  };
  config = mkIf cfg.enable {
    home.packages = [cfg.finalPackage];
    programs.firefox.profiles = flip mapAttrs cfg.firefoxIntegration.profiles (name: {enable, ...}: {
      settings = mkIf enable {
        "network.protocol-handler.app.afirma" = "${cfg.finalPackage}/bin/autofirma";
        "network.protocol-handler.warn-external.afirma" = false;
        "network.protocol-handler.external.afirma" = true;
      };
    });
  };
}
