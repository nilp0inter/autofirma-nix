{
  writeShellApplication,
  xmlstarlet,
}:
writeShellApplication {
  name = "update-pkg-version";
  runtimeInputs = [xmlstarlet];
  text = builtins.readFile ./update-pkg-version.sh;
}
