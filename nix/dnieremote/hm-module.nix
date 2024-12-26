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
    package = mkPackageOption inputs.self.packages.${system} "dnieremote" {};
    finalPackage = mkOption {
      type = types.package;
      readOnly = true;
      default = cfg.package;
      defaultText =
        literalExpression
        "`programs.dnieremote.package` with applied configuration";
      description = ''
        The DNIeRemote package after applying configuration.
      '';
    };
  };
  config = mkIf cfg.enable {
    home.packages = [cfg.finalPackage];
  };
}
