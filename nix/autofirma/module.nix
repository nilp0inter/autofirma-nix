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
    enable = mkEnableOption "AutoFirma";
    fixJavaCerts = mkEnableOption "Fix Java certificates";
    package = mkPackageOption inputs.self.packages.${system} "autofirma" {};
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
        The AutoFirma package after applying configuration.
      '';
    };
    firefoxIntegration.enable = mkEnableOption "Firefox integration";
  };
  config.environment.systemPackages = mkIf cfg.enable [cfg.finalPackage];
  config.environment.variables = mkIf cfg.fixJavaCerts {
    JAVAX_NET_SSL_TRUSTSTORE = let
      caBundle = config.environment.etc."ssl/certs/ca-bundle.crt".source;
      p11kit = pkgs.p11-kit.overrideAttrs (oldAttrs: {
        configureFlags = [
          "--with-trust-paths=${caBundle}"
        ];
      });
    in
      derivation {
        name = "java-cacerts";
        builder = pkgs.writeShellScript "java-cacerts-builder" ''
          ${p11kit.bin}/bin/trust \
            extract \
            --format=java-cacerts \
            --purpose=server-auth \
            $out
        '';
        system = "x86_64-linux";
      };
  };

  config.programs = mkIf cfg.enable {
    firefox = mkIf cfg.firefoxIntegration.enable {
      autoConfigFiles = lib.mkAfter [
        "${cfg.finalPackage}/etc/firefox/pref/AutoFirma.js"
      ];
    };
  };
}
