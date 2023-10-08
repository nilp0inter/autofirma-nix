{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  jre,
  runtimeShell,
}:
stdenv.mkDerivation rec {
  name = "configuradorfnmt";
  version = "4.0.2";
  src = fetchurl {
    url = "https://descargas.cert.fnmt.es/Linux/${name}_${version}_amd64.deb";
    hash = "sha256-pDzBC9/fa2OypnqBTmzujTH4825r3MExi0BsLmAfHmo=";
  };
  buildInputs = [
    dpkg
  ];
  unpackCmd = "dpkg-deb -x $src .";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/configuradorfnmt $out/share
    cp -r share/doc $out/share
    cp lib/configuradorfnmt/*.* $out/lib/configuradorfnmt
    runHook postInstall
  '';

  postInstall = ''
    mkdir -p $out/bin
    cat > $out/bin/configuradorfnmt <<EOF
    #!${runtimeShell}
    ${jre}/bin/java -classpath $out/lib/configuradorfnmt/configuradorfnmt.jar:$out/lib/configuradorfnmt/bcpkix-fips.jar:$out/lib/configuradorfnmt/bc-fips.jar es.gob.fnmt.cert.certrequest.CertRequest \$*
    EOF
    chmod +x $out/bin/configuradorfnmt

    mkdir -p $out/etc/firefox/pref
    cat > $out/etc/firefox/pref/configuradorfnmt.js <<EOF
    pref("network.protocol-handler.app.fnmtcr","$out/bin/configuradorfnmt");
    pref("network.protocol-handler.warn-external.fnmtcr",false);
    pref("network.protocol-handler.external.fnmtcr",true);
    EOF

    mkdir -p $out/share/applications
    cat > $out/share/applications/configuradorfnmt.desktop <<EOF
    [Desktop Entry]
    Encoding=UTF-8
    Name=Configurador FNMT
    Comment=Aplicación FNMT para la descarga e instalación de certificados
    Exec=$out/bin/configuradorfnmt %u
    Icon=$out/lib/configuradorfnmt/configuradorfnmt.png
    MimeType=x-scheme-handler/fnmtcr;
    Terminal=false
    Type=Application
    Categories=GNOME;Application;Office
    StartupNotify=true
    StartupWMClass=configuradorfnmt
    Version=${version}
    Keywords=fnmt;certificate
    EOF

  '';

  # postFixup = ''

  #   substituteInPlace $out/share/applications/configuradorfnmt.desktop \
  #     --replace "=/usr" "=$out"

  #   substituteInPlace $out/lib/configuradorfnmt/configuradorfnmt.js \
  #     --replace "/usr/bin/configuradorfnmt" "$out/bin/configuradorfnmt"
  # '';

  #   wrapProgram $out/bin/dnieremotewizard \
  #     --set PATH ${lib.makeBinPath [
  #     android-tools
  #   ]}
  # '';

  meta = with lib; {
    description = "Application to request the necessary keys for obtaining a digital certificate from the FNMT.";
    homepage = "https://www.sede.fnmt.gob.es/descargas/descarga-software/instalacion-software-generacion-de-claves";
    license = with licenses; []; # TODO: find out
    maintainers = with maintainers; [nilp0inter];
    mainProgram = "configuradorfnmt";
    platforms = platforms.linux;
  };
}
