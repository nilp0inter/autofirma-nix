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
    firefoxIntegration.enable = mkEnableOption "Firefox integration";
  };
  config = mkIf cfg.enable {
    environment.systemPackages = [cfg.finalPackage];
    programs.firefox = mkIf cfg.firefoxIntegration.enable {
      autoConfig = builtins.readFile "${cfg.finalPackage}/etc/firefox/pref/AutoFirma.js";
    };
  };
}
