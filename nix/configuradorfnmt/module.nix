inputs: {
  pkgs,
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.programs.configuradorfnmt;
  inherit (pkgs.stdenv.hostPlatform) system;
in {
  options.programs.configuradorfnmt = {
    enable = mkEnableOption "configuradorfnmt";
    package = mkPackageOptionMD inputs.self.packages.${system} "configuradorfnmt" {};
    finalPackage = mkOption {
      type = types.package;
      readOnly = true;
      default = cfg.package;
      defaultText =
        literalExpression
        "`programs.configuradorfnmt.package` with applied configuration";
      description = mdDoc ''
        The configuradorfnmt package after applying configuration.
      '';
    };
    firefoxIntegration.enable = mkEnableOption "Firefox integration";
  };
  config = mkIf cfg.enable {
    environment.systemPackages = [cfg.finalPackage];
    programs.firefox = mkIf cfg.firefoxIntegration.enable {
      autoConfig = builtins.readFile "${cfg.finalPackage}/etc/firefox/pref/configuradorfnmt.js";
    };
  };
}
