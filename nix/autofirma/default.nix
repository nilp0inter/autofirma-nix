{
  lib,
  stdenv,
  fetchFromGitHub,
  jre,
  makeWrapper,
  maven,
  nss,
  firefox,
  runtimeShell,
  JAVAX_NET_SSL_TRUSTSTORE ? null,
}: let
  pname = "autofirma";
  version = "1.8.2";
  jmulticard-src = stdenv.mkDerivation {
    name = "jmulticard-src";
    src = fetchFromGitHub {
      owner = "ctt-gob-es";
      repo = "jmulticard";
      rev = "v1.8";
      hash = "sha256-sCqMK4FvwRHsGIB6iQVyqrx0+EDiUfQSAsPqmDq2Giw=";
    };
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
      rev = "v1.0.5";
      hash = "sha256-cCH4iOvtAZ+9VsHG+MrfU5DkJ+cvXZvDTRDIamuBZZw=";
    };
    patches = [
      ./patches/clienteafirma-external/javaversion.patch
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
      hash = "sha256-YtGtTeWDWwCCIikxs6Cyrypb0EBX2Q2sa3CBCmC6kK8=";
    };
    patches = [
      ./patches/javaversion.patch
      ./patches/certutilpath.patch
      ./patches/nsspath.patch
      ./patches/pom.patch
    ];
    dontBuild = true;
    installPhase = ''
      mkdir -p $out/
      cp -R . $out/
    '';
    postPatch = ''
      substituteInPlace afirma-keystores-mozilla/src/main/java/es/gob/afirma/keystores/mozilla/MozillaKeyStoreUtilitiesUnix.java \
        --replace '@nsspath' '${nss}/lib' \
        --replace '@firefoxpath' '${firefox}/lib/firefox'

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
      outputHash = "sha256-m23F+jZV9P3jzDdnzk2luI9nQMxu1VKotSPJzShr1ss=";
    });
in
  stdenv.mkDerivation (source
    // {
      pname = pname;
      version = version;

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

        substituteInPlace $out/share/applications/afirma.desktop \
          --replace /usr/bin/autofirma $out/bin/autofirma \
          --replace /usr/lib/AutoFirma $out/lib/AutoFirma

        substituteInPlace $out/etc/firefox/pref/AutoFirma.js \
          --replace /usr/bin/autofirma $out/bin/autofirma

        makeWrapper ${jre}/bin/java $out/bin/autofirma \
          --add-flags "-Des.gob.afirma.keystores.mozilla.UseEnvironmentVariables=true" \
          --add-flags "-jar $out/lib/AutoFirma/AutoFirma.jar" \
          ${lib.optionalString (JAVAX_NET_SSL_TRUSTSTORE != null) "--set JAVAX_NET_SSL_TRUSTSTORE '${JAVAX_NET_SSL_TRUSTSTORE}'"}

        cat > $out/bin/autofirma-setup <<EOF
        #!${runtimeShell}
        ${jre}/bin/java -jar $out/lib/AutoFirma/AutoFirmaConfigurador.jar -jnlp
        chmod +x \$HOME/.afirma/AutoFirma/script.sh
        \$HOME/.afirma/AutoFirma/script.sh
        EOF
        chmod +x $out/bin/autofirma-setup

        runHook postInstall
      '';
      meta = with lib; {
        description = "Spanish Government digital signature tool";
        homepage = "https://firmaelectronica.gob.es/Home/Ciudadanos/Aplicaciones-Firma.html";
        license = with licenses; [gpl2Only eupl11];
        maintainers = with maintainers; [nilp0inter];
        mainProgram = "autofirma";
        platforms = platforms.linux;
      };
    })
