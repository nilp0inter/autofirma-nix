inputs: {
  pkgs,
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.programs.DNIeRemote;
  inherit (pkgs.stdenv.hostPlatform) system;
in {
  options.programs.DNIeRemote = {
    enable = mkEnableOption "DNIeRemote";
    package = mkPackageOptionMD inputs.self.packages.${system} "DNIeRemote" {};
    finalPackage = mkOption {
      type = types.package;
      readOnly = true;
      default = cfg.package;
      defaultText =
        literalExpression
        "`programs.DNIeRemote.package` with applied configuration";
      description = mdDoc ''
        The DNIeRemote package after applying configuration.
      '';
    };
  };
  config = mkIf cfg.enable {
    environment.systemPackages = [cfg.finalPackage];
  };
}
