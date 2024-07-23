{
  lib,
  writeShellApplication,
  xmlstarlet,
  symlinkJoin
}:
let
  scripts = {
    update-java-version = ./scripts/update-java-version.sh;
    update-pkg-version = ./scripts/update-pkg-version.sh;
    update-dependency-version-by-groupId = ./scripts/update-dependency-version-by-groupId.sh;
    remove-module-on-profile = ./scripts/remove-module-on-profile.sh;
    reset-project-build-timestamp = ./scripts/reset-project-build-timestamp.sh;
    reset-maven-metadata-local-timestamp = ./scripts/reset-maven-metadata-local-timestamp.sh;
  };
in symlinkJoin {
  name = "pom-tools";
  paths = lib.mapAttrsToList (name: path: writeShellApplication {
    name = name;
    runtimeInputs = [ xmlstarlet ];
    text = builtins.readFile path;
  }) scripts;
}
