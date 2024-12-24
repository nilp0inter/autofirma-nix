{
  lib,
  writeShellApplication,
  xmlstarlet,
  symlinkJoin,
}: let
  scripts = {
    update-java-version = ./lib/update-java-version.sh;
    update-pkg-version = ./lib/update-pkg-version.sh;
    update-dependency-version-by-groupId = ./lib/update-dependency-version-by-groupId.sh;
    remove-module-on-profile = ./lib/remove-module-on-profile.sh;
    reset-project-build-timestamp = ./lib/reset-project-build-timestamp.sh;
    reset-maven-metadata-local-timestamp = ./lib/reset-maven-metadata-local-timestamp.sh;
  };
in
  symlinkJoin {
    name = "pom-tools";
    paths = lib.mapAttrsToList (name: path:
      writeShellApplication {
        name = name;
        runtimeInputs = [xmlstarlet];
        text = builtins.readFile path;
      })
    scripts;
  }
