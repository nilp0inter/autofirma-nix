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
  name = "jmulticard";

  version = "1.8";

  jmulticard-src = stdenv.mkDerivation {
    name = "${name}-src";

    src = fetchFromGitHub {
      owner = "ctt-gob-es";
      repo = "jmulticard";
      rev = "v${version}";
      hash = "sha256-sCqMK4FvwRHsGIB6iQVyqrx0+EDiUfQSAsPqmDq2Giw=";
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
      update-dependency-version-by-groupId "es.gob.afirma.jmulticard" "${version}-autofirma-nix"
    '';

    installPhase = ''
      mkdir -p $out/
      cp -R . $out/
    '';

    dontFixup = true;
  };

  jmulticard-dependencies = stdenv.mkDerivation {
    name = "${name}-dependencies";

    src = jmulticard-src;

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

      rm -rf $out/.m2/respository/es/gob/afirma/jmulticard

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
    outputHash = "sha256-qI6gYbGKTQ4Q4tV8NI37TSd3eQTyHHgndUGS943UvNU=";
  };
in
  stdenv.mkDerivation {
    pname = "${name}-m2-repository";
    version = version;

    groupId = "es.gob.afirma.jmulticard";
    finalVersion = "${version}-autofirma-nix";

    src = jmulticard-src;

    nativeBuildInputs = [
      rsync
      maven
    ];

    buildPhase = ''
      cp -r ${jmulticard-dependencies}/.m2 ./ && chmod -R u+w .m2

      mvn --offline package -Dmaven.repo.local=./.m2/repository -DskipTests
    '';

    installPhase = ''
      mkdir -p $out/.m2/repository/es/gob/afirma/jmulticard

      rm -rf ./.m2/repository/es/gob/afirma/jmulticard

      mvn --offline install -Dmaven.repo.local=./.m2/repository -DskipTests

      rsync -av ./.m2/repository/es/gob/afirma/jmulticard $out/.m2/repository/es/gob/afirma/

      find $out -type f \( \
        -name \*.lastUpdated \
        -o -name resolver-status.properties \
        -o -name _remote.repositories \) \
        -delete
    '';

    meta = with lib; {
      description = "Capa abstracta de acceso a tarjetas inteligentes 100% java";
      homepage = "https://github.com/ctt-gob-es/jmulticard";
      license = with licenses; [gpl2Only eupl11];
      maintainers = with maintainers; [nilp0inter];
      platforms = platforms.linux;
    };
  }
