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
    trustStore = mkOption {
      type = types.package;
      default = let
        caBundle = config.environment.etc."ssl/certs/ca-bundle.crt".source;
        p11kit = pkgs.p11-kit.overrideAttrs (oldAttrs: {
          configureFlags = [
            "--with-trust-paths=${caBundle}"
          ];
        });
      in
        derivation {
          name = "autofirma-trust-store";
          builder = pkgs.writeShellScript "java-cacerts-builder" ''
            ${p11kit.bin}/bin/trust \
              extract \
              --format=java-cacerts \
              --purpose=server-auth \
              $out
          '';
          system = system;
        };

      description = mdDoc ''
        The path to the trust store used by Autofirma.
      '';
    };
    finalPackage = mkOption {
      type = types.package;
      readOnly = true;
      default = cfg.package.override {
        JAVAX_NET_SSL_TRUSTSTORE = cfg.trustStore;
      };
      defaultText =
        literalExpression
        "`programs.autofirma.package` with applied configuration";
      description = mdDoc ''
        The Autofirma package after applying configuration.
      '';
    };
  };
  config = mkIf cfg.enable {
    environment.systemPackages = [cfg.finalPackage];
  };
}
