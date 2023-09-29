{ stdenv, fetchzip, dpkg, autoPatchelfHook, gtkmm3, atkmm, glibmm, gtk3, pango, at-spi2-atk, cairo, openssl_1_1 }:
stdenv.mkDerivation rec {
  name = "DNIeRemote";
  version = "1.0-5";
  src = fetchzip {
    url = "https://www.dnie.es/descargas/Apps/DNIeRemote_${version}_amd64.zip";
    hash = "sha256-NLIbgLknfHq6volGv9X3mBgIAdpcvnAo8fMBDeIGSQQ=";
    stripRoot = false;
  };
  buildInputs = [
    dpkg
    gtkmm3
    atkmm
    glibmm
    gtk3
    pango
    at-spi2-atk
    cairo
    openssl_1_1
  ];
  nativeBuildInputs = [ 
    autoPatchelfHook
  ];
  unpackCmd = "dpkg-deb -x $src/DNIeRemoteSetup_${version}_amd64.deb .";
  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r bin local/lib share $out
    runHook postInstall
  '';
}
