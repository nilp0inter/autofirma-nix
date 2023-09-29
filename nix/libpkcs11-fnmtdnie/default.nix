{ lib, stdenv, fetchurl, dpkg, autoPatchelfHook, libgcc, pcsclite, libassuan, libgpg-error }:
stdenv.mkDerivation rec {
  name = "libpkcs11-fnmtdnie";
  version = "1.6.8";
  src = fetchurl {
    url = "https://www.sede.fnmt.gob.es/documents/10445900/10876934/${name}_${version}_Debian_10_Buster_Debian_11_64bits.deb";
    hash = "sha256-x+QRRSC6Cq0eQZiEe+O2IwLhfJf0SWOAsqesLNDMd1w=";
  };
  buildInputs = [
    dpkg
    libgcc.lib
    pcsclite
    libassuan
    libgpg-error
  ];
  nativeBuildInputs = [ 
    autoPatchelfHook
  ];
  unpackCmd = "dpkg-deb -x $src/${name}_${version}_amd64.deb .";
  installPhase = ''
    runHook preInstall
    mkdir -p $out
    ls -la usr
    cp -r usr/* $out
    runHook postInstall
  '';
  # meta = with lib; {
  #   description = "Enables NFC-based DNIe 3.0 reading for PCs, offering digital authentication for Spain's electronic administration services";
  #   homepage = "https://www.dnielectronico.es/PortalDNIe/PRF1_Cons02.action?pag=REF_1015&id_menu=65";
  #   license = with licenses; [ ];  # TODO: find out
  #   maintainers = with maintainers; [ nilp0inter ];
  #   mainProgram = "dnieremotewizard";
  #   platforms = platforms.linux;
  # };
}
