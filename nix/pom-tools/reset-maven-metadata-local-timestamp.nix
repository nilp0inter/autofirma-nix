{
  writeShellApplication,
  xmlstarlet,
}:
writeShellApplication {
  name = "reset-maven-metadata-local-timestamp";
  runtimeInputs = [xmlstarlet];
  text = builtins.readFile ./reset-maven-metadata-local-timestamp.sh;
}
