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
  options.programs.autofirma.truststore = {
    package = mkPackageOption inputs.self.packages.${system} "autofirma-truststore" {};
    finalPackage = mkOption {
      type = types.package;
      readOnly = true;
      default = cfg.truststore.package.override { caBundle = config.environment.etc."ssl/certs/ca-certificates.crt".source; };
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
    fixJavaCerts = mkEnableOption "Fix Java certificates";
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
    firefoxIntegration.enable = mkEnableOption "Firefox integration";
  };

  config.environment.systemPackages = mkIf cfg.enable (lib.warnIf cfg.fixJavaCerts "The option `programs.autofirma.fixJavaCerts` is deprecated." [cfg.finalPackage]);

  config.programs = mkIf cfg.enable {
    firefox = mkIf cfg.firefoxIntegration.enable {
      autoConfigFiles = lib.mkAfter [
        "${cfg.finalPackage}/etc/firefox/pref/AutoFirma.js"
      ];
    };
  };

}
