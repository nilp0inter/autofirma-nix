{fetchurl}: let
  trusted-providers = builtins.fromJSON (builtins.readFile ./providers.json);
  read-provider-certs = provider: map (cert: {inherit provider cert;}) (builtins.fromJSON (builtins.readFile ./CAs-by-provider/${provider.cif}.json));
  fetch-ca = trusted:
    fetchurl {
      url = trusted.cert.url;
      sha256 = trusted.cert.hash;
      curlOptsList = trusted.cert.curlOptsList or [];
      meta = {inherit trusted;};
    };
in
  map fetch-ca (builtins.concatMap read-provider-certs trusted-providers)
