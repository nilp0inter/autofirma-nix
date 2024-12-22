{
  lib,
  openssl,
  stdenv,
  jre,
  writeShellScript,
  runCommand,
  caBundle,
  govTrustedCerts ? [], # Trust no one. The trust is out there.
  storepass ? "autofirma",
}: let
  add-cert-to-truststore = cert: let
    cif = lib.attrsets.attrByPath ["meta" "trusted" "provider" "cif"] "unknown-cif" cert;
    url = lib.attrsets.attrByPath ["meta" "trusted" "cert" "url"] "unknown-url" cert;
    alias = "${cif}-${url}";
  in
    writeShellScript "add-cert-to-truststore" ''
      ${openssl}/bin/openssl verify -CAfile ${caBundle} ${cert} && exec ${jre}/bin/keytool -importcert -noprompt -alias "${alias}" -keystore "$1" -storepass ${storepass} -file ${cert} || echo "Invalid cert or not present in ca-bundle."
    '';
  to-pem-file = cert:
    runCommand "${cert.name}.pem" {} ''
      echo >> $out
      echo "NAME: ${lib.attrsets.attrByPath ["meta" "trusted" "provider" "name"] "unknown-name" cert}" >> $out
      echo "CIF: ${lib.attrsets.attrByPath ["meta" "trusted" "provider" "cif"] "unknown-cif" cert}" >> $out
      echo "URL: ${lib.attrsets.attrByPath ["meta" "trusted" "cert" "url"] "unknown-url" cert}" >> $out
      ${lib.getExe openssl} x509 -in ${cert} -out - >> $out
    '';
in
  stdenv.mkDerivation {
    name = "autofirma-truststore";
    srcs = builtins.map add-cert-to-truststore govTrustedCerts;
    phases = ["buildPhase"];
    buildPhase = ''
      for addValidatedCertToTruststore in $srcs; do
        $addValidatedCertToTruststore $out
      done
    '';
    passthru = {
      pemBundle = stdenv.mkDerivation {
        name = "autofirma-truststore-bundle.pem";
        srcs = builtins.map to-pem-file govTrustedCerts;
        phases = ["installPhase"];
        installPhase = ''
          for _src in $srcs; do
            ${openssl}/bin/openssl verify -CAfile ${caBundle} $_src && cat $_src >> $out
          done
        '';
      };
    };
  }
