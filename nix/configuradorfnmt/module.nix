inputs: {
  pkgs,
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.programs.dnieremote;
  inherit (pkgs.stdenv.hostPlatform) system;
in {
  options.programs.dnieremote = {
    enable = mkEnableOption "DNIeRemote";
    package = mkPackageOptionMD inputs.self.packages.${system} "dnieremote" {};
    finalPackage = mkOption {
      type = types.package;
      readOnly = true;
      default = cfg.package;
      defaultText =
        literalExpression
        "`programs.dnieremote.package` with applied configuration";
      description = mdDoc ''
        The DNIeRemote package after applying configuration.
      '';
    };
    firefoxIntegration.enable = mkEnableOption "Firefox integration";
  };
  config = mkIf cfg.enable {
    environment.systemPackages = [cfg.finalPackage];
    programs.firefox = mkIf cfg.firefoxIntegration.enable {
      autoConfig = builtins.readFile "${cfg.finalPackage}/lib/configuradorfnmt/configuradorfnmt.js";
    };
  };
}
