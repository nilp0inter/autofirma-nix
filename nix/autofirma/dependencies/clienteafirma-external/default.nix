{
  lib,
  stdenv,
  fetchFromGitHub,
  maven,
  pom-tools-update-java-version,
  pom-tools-update-pkg-version,
  pom-tools-update-dependency-version-by-groupId,
  rsync,
}: let
  name = "clienteafirma-external";

  version = "1.0.6";

  clienteafirma-external-src = stdenv.mkDerivation {
    name = "${name}-src";

    src = fetchFromGitHub {
      owner = "ctt-gob-es";
      repo = "clienteafirma-external";
      rev = "OT_14395";
      hash = "sha256-iS3I6zIxuKG133s/FqDlXZzOZ2ZOJcqZK9X6Tv3+3lc=";
    };

    nativeBuildInputs = [
      pom-tools-update-java-version
      pom-tools-update-pkg-version
      pom-tools-update-dependency-version-by-groupId
    ];

    dontBuild = true;

    patchPhase = ''
      find . -name '*.jar' -delete  # just in case

      update-java-version "1.8"
      update-pkg-version "${version}-autofirma-nix"
      update-dependency-version-by-groupId "es.gob.afirma.lib" "${version}-autofirma-nix"
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
    outputHash = "sha256-N2lFeRM/eu/tMFTCQRYSHYrbXNgbAv49S7qTaUmb2+Q=";
  };
in
  stdenv.mkDerivation {
    pname = "${name}-m2-repository";
    version = version;

    groupId = "es.gob.afirma.lib";
    finalVersion = "${version}-autofirma-nix";

    src = clienteafirma-external-src;

    nativeBuildInputs = [maven rsync];

    buildPhase = ''
      cp -r ${clienteafirma-external-dependencies}/.m2 ./ && chmod -R u+w .m2

      mvn --offline package -Dmaven.repo.local=./.m2/repository -DskipTests
    '';

    installPhase = ''
      mkdir -p $out/.m2/repository/es/gob/afirma/lib

      rm -rf ./.m2/repository/es/gob/afirma/lib

      mvn --offline install -Dmaven.repo.local=./.m2/repository -DskipTests

      rsync -av ./.m2/repository/es/gob/afirma/lib $out/.m2/repository/es/gob/afirma/

      find $out -type f \( \
        -name \*.lastUpdated \
        -o -name resolver-status.properties \
        -o -name _remote.repositories \) \
        -delete
    '';

    meta = with lib; {
      description = "External libraries used by Cliente @firma";
      homepage = "https://github.com/ctt-gob-es/clienteafirma-external";
      license = with licenses; [gpl2Only eupl11];
      maintainers = with maintainers; [nilp0inter];
      platforms = platforms.linux;
    };
  }
