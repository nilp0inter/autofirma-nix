{ writeShellApplication, xmlstarlet }:
writeShellApplication {
  name = "update-java-version";
  runtimeInputs = [ xmlstarlet ];
  text = builtins.readFile ./update-java-version.sh;
}
