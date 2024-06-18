{
  lib,
  stdenv,
  buildFHSEnv,
  fetchFromGitHub,
  jre,
  makeDesktopItem,
  makeWrapper,
  maven,
  nss,
  firefox,
  runtimeShell
}: let
  pname = "autofirma";
  version = "1.8.3";
  jmulticard-src = stdenv.mkDerivation {
    name = "jmulticard-src";
    src = fetchFromGitHub {
      owner = "ctt-gob-es";
      repo = "jmulticard";
      rev = "v1.9";
      hash = "sha256-lMkQ+2oL37voZ7NpsxGJm9qDGWEsi6WQDRy9GFsIX10=";
    };
    patches = [
      ./patches/jmulticard/javaversion.patch
    ];
    dontBuild = true;
    installPhase = ''
      mkdir -p $out/
      cp -R . $out/
    '';
    dontFixup = true;
  };
  clienteafirma-external-src = stdenv.mkDerivation {
    name = "clienteafirma-external-src";
    src = fetchFromGitHub {
      name = "clienteafirma-external";
      owner = "ctt-gob-es";
      repo = "clienteafirma-external";
      rev = "c674ad5b07c66907994f63ba73ca61c9c49c8d2c";
      hash = "sha256-b4z9uDcPj+bBhqB2caaal9vpMErVCHx/IMJKJuhtU2c=";
    };
    patches = [
      ./patches/clienteafirma-external/javaversion.patch
      ./patches/clienteafirma-external/afirma-lib-oro-version.patch
    ];
    dontBuild = true;
    installPhase = ''
      mkdir -p $out/
      cp -R . $out/
    '';
    dontFixup = true;
  };
  clienteafirma-src = stdenv.mkDerivation {
    name = "clienteafirma-src";
    src = fetchFromGitHub {
      name = "clienteafirma";
      owner = "ctt-gob-es";
      repo = "clienteafirma";
      rev = "v${version}";
      hash = "sha256-GQyj3QuWIHTkYwdJ4oKVsG923YG9mCUXfhqdIvEWNMA=";
    };
    patches = [
      ./patches/clienteafirma/detect_java_version.patch
      ./patches/clienteafirma/pr-367.patch
      ./patches/clienteafirma/javaversion.patch
      ./patches/clienteafirma/certutilpath.patch
      ./patches/clienteafirma/pom.patch
      ./patches/clienteafirma/afirma-core-pom.patch
    ];
    dontBuild = true;
    installPhase = ''
      mkdir -p $out/
      cp -R . $out/
    '';

    postPatch = ''
      substituteInPlace afirma-ui-simple-configurator/src/main/java/es/gob/afirma/standalone/configurator/ConfiguratorFirefoxLinux.java \
        --replace '@certutilpath' '${nss.tools}/bin/certutil'
    '';
    dontFixup = true;
  };
  source = {
    srcs = [
      jmulticard-src
      clienteafirma-external-src
      clienteafirma-src
    ];
    sourceRoot = clienteafirma-src.name;
  };

  afirma-libs = stdenv.mkDerivation (source
    // {
      name = "${pname}-${version}-maven-deps";

      nativeBuildInputs = [
        maven
      ];

      buildPhase = ''
        runHook preBuild

        cd ${jmulticard-src}
        mvn clean dependency:go-offline -Dmaven.repo.local=$out/.m2

        cd ${clienteafirma-external-src}
        mvn clean dependency:go-offline -Dmaven.repo.local=$out/.m2

        cd ${clienteafirma-src}
        mvn clean dependency:go-offline -Dmaven.repo.local=$out/.m2 -Denv=dev

        # The following command downloads all dependencies from mavencentral, including the ones that
        # we are interested in building.
        mvn clean dependency:go-offline -Dmaven.repo.local=$out/.m2 -Denv=install

        # So we need to remove them from the local repository, while keeping
        # es/gob/afirma/lib which contains some dependencies that are not in this
        # repository.
        # rm -Rf $out/.m2/es/gob/afirma/afirma-*
        rm -Rf $out/.m2/es/gob/afirma

        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall

        find $out -type f \( \
          -name \*.lastUpdated \
          -o -name resolver-status.properties \
          -o -name _remote.repositories \) \
          -delete

        runHook postInstall
      '';

      dontFixup = true;
      outputHashAlgo = "sha256";
      outputHashMode = "recursive";
      outputHash = "sha256-mIgarm9CUnaD2Bc4hbtKYT+lPHZyeq5WMKz0gWYTbxA=";
    });

    meta = with lib; {
      description = "Spanish Government digital signature tool";
      homepage = "https://firmaelectronica.gob.es/Home/Ciudadanos/Aplicaciones-Firma.html";
      license = with licenses; [gpl2Only eupl11];
      maintainers = with maintainers; [nilp0inter];
      mainProgram = "autofirma";
      platforms = platforms.linux;
    };

    thisPkg = stdenv.mkDerivation (source
      // {
        pname = pname;
        version = version;
        inherit meta;

        nativeBuildInputs = [makeWrapper maven];

        propagatedBuildInputs = [nss.tools];

        buildPhase = ''
          runHook preBuild

          mvnDeps=$(cp -dpR ${afirma-libs}/.m2 ./ && chmod +w -R .m2 && pwd)

          cp -dpR ${jmulticard-src} ./jmulticard
          chmod +w -R jmulticard
          cd jmulticard
          mvn clean install -o -nsu "-Dmaven.repo.local=$mvnDeps/.m2" -DskipTests
          cd ..


          cp -dpR ${clienteafirma-external-src} ./clienteafirma-external
          chmod +w -R clienteafirma-external
          cd clienteafirma-external
          mvn clean install -o -nsu "-Dmaven.repo.local=$mvnDeps/.m2" -DskipTests
          cd ..

          cp -dpR ${clienteafirma-src} ./clienteafirma
          chmod +w -R clienteafirma
          cd clienteafirma

          mvn clean install -o -nsu "-Dmaven.repo.local=$mvnDeps/.m2" -Denv=dev -DskipTests
          mvn clean package -o -nsu "-Dmaven.repo.local=$mvnDeps/.m2" -Denv=install -DskipTests

          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          mkdir -p $out/bin $out/lib/AutoFirma
          install -Dm644 afirma-simple/target/AutoFirma.jar $out/lib/AutoFirma
          install -Dm644 afirma-ui-simple-configurator/target/AutoFirmaConfigurador.jar $out/lib/AutoFirma
          cp -r afirma-simple-installer/linux/instalador_deb/src/usr/lib $out
          cp -r afirma-simple-installer/linux/instalador_deb/src/usr/share $out
          cp -r afirma-simple-installer/linux/instalador_deb/src/etc $out

          substituteInPlace $out/etc/firefox/pref/AutoFirma.js \
            --replace /usr/bin/autofirma $out/bin/autofirma

          makeWrapper ${jre}/bin/java $out/bin/autofirma \
            --add-flags "-Des.gob.afirma.keystores.mozilla.UseEnvironmentVariables=true" \
            --add-flags "-jar $out/lib/AutoFirma/AutoFirma.jar"

          cat > $out/bin/autofirma-setup <<EOF
          #!${runtimeShell}
          ${jre}/bin/java -jar $out/lib/AutoFirma/AutoFirmaConfigurador.jar -jnlp
          chmod +x \$HOME/.afirma/AutoFirma/script.sh
          \$HOME/.afirma/AutoFirma/script.sh
          EOF
          chmod +x $out/bin/autofirma-setup

          runHook postInstall
        '';

      });

  desktopItem = (makeDesktopItem {
    name = "AutoFirma";
    desktopName = "AutoFirma";
    genericName = "Herramienta de firma";
    exec = "autofirma %u";
    icon = "${thisPkg}/lib/AutoFirma/AutoFirma.png";
    mimeTypes = ["x-scheme-handler/afirma"];
    categories = ["Office" "X-Utilities" "X-Signature" "Java"];
    startupNotify = true;
    startupWMClass = "autofirma";
  });
in thisPkg
# in buildFHSEnv {
#   name = pname;
#   inherit meta;
#   targetPkgs = (pkgs: [
#     firefox
#     pkgs.nss
#   ]);
#   runScript = lib.getExe thisPkg;
#   extraInstallCommands = ''
#     mkdir -p "$out/share/applications"
#     cp "${desktopItem}/share/applications/"* $out/share/applications

#     mkdir -p $out/etc/firefox/pref
#     ln -s ${thisPkg}/etc/firefox/pref/AutoFirma.js $out/etc/firefox/pref/AutoFirma.js
#     ln -s ${thisPkg}/bin/autofirma-setup $out/bin/autofirma-setup
#   '';
# }
