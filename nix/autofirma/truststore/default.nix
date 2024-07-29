{
  lib,
  stdenv,
  jre,
  xmlstarlet,
  curl,
  fetchurl,
  writeShellApplication,
  storepass ? "autofirma",
}: let
  trusted-providers = builtins.fromJSON (builtins.readFile ./trusted-providers.json);
  read-provider-certs = provider: builtins.map (cert: {inherit provider cert;}) (builtins.fromJSON (builtins.readFile ./cert-sources/${provider.cif}.json));
  add-cert-to-truststore = trusted: let
    cert = fetchurl {
      url = trusted.cert.url;
      hash = trusted.cert.hash;
      meta = trusted.provider;
    };
  in
    writeShellApplication {
      name = "add-cert-to-truststore";
      runtimeInputs = [jre];
      text = ''
        set -x
        ${jre}/bin/keytool -importcert -noprompt -alias "${trusted.provider.cif}-${trusted.cert.hash}" -keystore "$1" -storepass ${storepass} -file ${cert}
      '';
    };
in
  stdenv.mkDerivation {
    name = "autofirma-truststore";
    srcs = builtins.map add-cert-to-truststore (builtins.concatMap read-provider-certs trusted-providers);
    phases = ["buildPhase"];
    buildPhase = ''
      for _src in $srcs; do
        $_src/bin/add-cert-to-truststore $out
      done
    '';
  }
