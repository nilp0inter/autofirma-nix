{
  writeShellApplication,
  xmlstarlet,
}:
writeShellApplication {
  name = "reset-project-build-timestamp";
  runtimeInputs = [xmlstarlet];
  text = builtins.readFile ./reset-project-build-timestamp.sh;
}
