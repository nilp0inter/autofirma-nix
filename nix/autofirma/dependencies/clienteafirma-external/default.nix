{
  lib,
  stdenv,
  fetchFromGitHub,
  maven,
  pom-tools,
  rsync,
  src-rev,
  src-hash,
  maven-dependencies-hash ? "",
}: let
  name = "clienteafirma-external";

  clienteafirma-external-src = stdenv.mkDerivation {
    name = "${name}-src";

    src = fetchFromGitHub {
      owner = "ctt-gob-es";
      repo = "clienteafirma-external";
      rev = src-rev;
      hash = src-hash;
    };

    nativeBuildInputs = [ pom-tools ];

    dontBuild = true;

    patchPhase = ''
      find . -name '*.jar' -delete  # just in case

      update-java-version "1.8"
      update-pkg-version "${src-rev}-autofirma-nix"
      update-dependency-version-by-groupId "es.gob.afirma.lib" "${src-rev}-autofirma-nix"
      reset-project-build-timestamp
    '';

    installPhase = ''
      mkdir -p $out/
      cp -R . $out/
    '';

    dontFixup = true;
  };

  clienteafirma-external-dependencies = stdenv.mkDerivation {
    name = "${name}-dependencies";

    src = clienteafirma-external-src;

    nativeBuildInputs = [
      maven
    ];

    buildPhase = ''
      runHook preBuild

      mkdir -p $out/.m2/repository

      mvn clean package dependency:go-offline -Dmaven.repo.local=$out/.m2/repository -DskipTests

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      rm -rf $out/.m2/respository/es/gob/afirma/lib

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
in
  stdenv.mkDerivation {
    pname = "${name}-m2-repository";
    version = src-rev;

    groupId = "es.gob.afirma.lib";
    finalVersion = "${src-rev}-autofirma-nix";

    src = clienteafirma-external-src;

    nativeBuildInputs = [
      maven
      rsync
      pom-tools
    ];

    buildPhase = ''
      cp -r ${clienteafirma-external-dependencies}/.m2 . && chmod -R u+w .m2

      mvn --offline package -Dmaven.repo.local=.m2/repository -DskipTests
    '';

    installPhase = ''
      mkdir -p $out/.m2/repository/es/gob/afirma/lib

      rm -rf .m2/repository/es/gob/afirma/lib

      mvn --offline install -Dmaven.repo.local=.m2/repository -DskipTests

      rsync -av .m2/repository/es/gob/afirma/lib $out/.m2/repository/es/gob/afirma/

      find $out -type f \( \
        -name \*.lastUpdated \
        -o -name resolver-status.properties \
        -o -name _remote.repositories \) \
        -delete
    '';

    fixupPhase = ''
      cd $out/.m2/repository
      reset-maven-metadata-local-timestamp
    '';

    meta = with lib; {
      description = "External libraries used by Cliente @firma";
      homepage = "https://github.com/ctt-gob-es/clienteafirma-external";
      license = with licenses; [gpl2Only eupl11];
      maintainers = with maintainers; [nilp0inter];
      platforms = platforms.linux;
    };
  }
