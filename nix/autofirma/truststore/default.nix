{
  lib,
  openssl,
  stdenv,
  jre,
  writeShellApplication,
  runCommand,
  trustedCerts ? [], # Trust no one. The trust is out there.
  storepass ? "autofirma",
}: let
  add-cert-to-truststore = cert: let
    cif = lib.attrsets.attrByPath ["meta" "trusted" "provider" "cif"] "unknown-cif" cert;
    url = lib.attrsets.attrByPath ["meta" "trusted" "cert" "url"] "unknown-url" cert;
    alias = "${cif}-${url}";
  in
    writeShellApplication {
      name = "add-cert-to-truststore";
      runtimeInputs = [jre];
      text = ''
        set -x
        ${jre}/bin/keytool -importcert -noprompt -alias "${alias}" -keystore "$1" -storepass ${storepass} -file ${cert}
      '';
    };
  to-pem-file = cert:
    runCommand "${cert.name}.pem" {} ''
      ${lib.getExe openssl} x509 -in ${cert} -out $out
    '';
in
  stdenv.mkDerivation {
    name = "autofirma-truststore";
    srcs = builtins.map add-cert-to-truststore trustedCerts;
    phases = ["buildPhase"];
    buildPhase = ''
      for _src in $srcs; do
        $_src/bin/add-cert-to-truststore $out
      done
    '';
    passthru = {
      pemBundle = stdenv.mkDerivation {
        name = "autofirma-truststore-bundle.pem";
        srcs = builtins.map to-pem-file trustedCerts;
        phases = ["installPhase"];
        installPhase = ''
          for _src in $srcs; do
            cat $_src >> $out
          done
        '';
      };
    };
  }
