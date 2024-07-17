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
  runtimeShell,
  pom-tools,
  jmulticard,
  clienteafirma-external,
  rsync,
  src-rev,
  src-hash,
  maven-dependencies-hash ? "",
}: let
  name = "autofirma";

  clienteafirma-src = stdenv.mkDerivation {
    name = "clienteafirma-src";

    src = fetchFromGitHub {
      name = "clienteafirma";
      owner = "ctt-gob-es";
      repo = "clienteafirma";
      rev = src-rev;
      hash = src-hash;
    };

    nativeBuildInputs = [
      pom-tools.update-java-version
      pom-tools.update-pkg-version
      pom-tools.update-dependency-version-by-groupId
      pom-tools.remove-module-on-profile
      pom-tools.reset-project-build-timestamp
    ];

    patches = [
      ./patches/clienteafirma/detect_java_version.patch
      ./patches/clienteafirma/pr-367.patch
      ./patches/clienteafirma/certutilpath.patch
    ];

    dontBuild = true;

    installPhase = ''
      mkdir -p $out/
      cp -R . $out/
    '';

    postPatch = ''
      update-java-version "1.8"
      update-pkg-version "${src-rev}-autofirma-nix"

      update-dependency-version-by-groupId "${clienteafirma-external.groupId}" "${clienteafirma-external.finalVersion}"
      update-dependency-version-by-groupId "${jmulticard.groupId}" "${jmulticard.finalVersion}"
      update-dependency-version-by-groupId "es.gob.afirma" "${src-rev}-autofirma-nix"

      remove-module-on-profile "env-install" "afirma-server-triphase-signer"
      remove-module-on-profile "env-install" "afirma-signature-retriever"
      remove-module-on-profile "env-install" "afirma-signature-storage"

      reset-project-build-timestamp

      substituteInPlace afirma-ui-simple-configurator/src/main/java/es/gob/afirma/standalone/configurator/ConfiguratorFirefoxLinux.java \
        --replace '@certutilpath' '${nss.tools}/bin/certutil'
    '';

    dontFixup = true;
  };

  clienteafirma-dependencies = stdenv.mkDerivation {
    name = "${name}-dependencies";

    src = clienteafirma-src;

    nativeBuildInputs = [
      maven
      rsync
    ];

    buildPhase = ''
      runHook preBuild

      mkdir -p $out/.m2/repository

      rsync -av ${jmulticard}/.m2/repository/ \
                ${clienteafirma-external}/.m2/repository/ \
                $out/.m2/repository/

      chmod -R +w $out/.m2/repository

      mvn install -Dmaven.repo.local=$out/.m2/repository -DskipTests -Denv=dev  # Some install modules are only declared in the dev profile
                                                                                # but are needed in the install profile.  We delete them later.
      mvn dependency:go-offline -Dmaven.repo.local=$out/.m2/repository -DskipTests -Denv=install

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      rm -rf $out/.m2/repository/es/gob/afirma  # Remove the modules that should be compiled in the build derivation. See above.

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
    outputHash = maven-dependencies-hash;
  };

  meta = with lib; {
    description = "Spanish Government digital signature tool";
    homepage = "https://firmaelectronica.gob.es/Home/Ciudadanos/Aplicaciones-Firma.html";
    license = with licenses; [gpl2Only eupl11];
    maintainers = with maintainers; [nilp0inter];
    mainProgram = "autofirma";
    platforms = platforms.linux;
  };

  thisPkg = stdenv.mkDerivation {
    pname = name;
    version = src-rev;

    src = clienteafirma-src;

    inherit meta;

    nativeBuildInputs = [
      makeWrapper
      maven
      rsync
    ];

    propagatedBuildInputs = [nss.tools];

    buildPhase = ''
      cp -r ${clienteafirma-dependencies}/.m2 .

      rsync -av ${jmulticard}/.m2/repository/ \
                ${clienteafirma-external}/.m2/repository/ \
                .m2/repository

      chmod -R u+w .m2

      mvn --offline install -Dmaven.repo.local=.m2/repository -DskipTests -Denv=dev  # As in the dependencies derivation, some modules are only declared in the dev profile
                                                                                     # but are needed in the install profile.
      mvn --offline package -Dmaven.repo.local=.m2/repository -DskipTests -Denv=install
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
  };

  desktopItem = makeDesktopItem {
    name = "AutoFirma";
    desktopName = "AutoFirma";
    genericName = "Herramienta de firma";
    exec = "autofirma %u";
    icon = "${thisPkg}/lib/AutoFirma/AutoFirma.png";
    mimeTypes = ["x-scheme-handler/afirma"];
    categories = ["Office" "X-Utilities" "X-Signature" "Java"];
    startupNotify = true;
    startupWMClass = "autofirma";
  };
in
  buildFHSEnv {
    name = name;
    inherit meta;
    targetPkgs = pkgs: [
      firefox
      pkgs.nss
    ];
    runScript = lib.getExe thisPkg;
    extraInstallCommands = ''
      mkdir -p "$out/share/applications"
      cp "${desktopItem}/share/applications/"* $out/share/applications

      mkdir -p $out/etc/firefox/pref
      ln -s ${thisPkg}/etc/firefox/pref/AutoFirma.js $out/etc/firefox/pref/AutoFirma.js
      ln -s ${thisPkg}/bin/autofirma-setup $out/bin/autofirma-setup
    '';
  }
