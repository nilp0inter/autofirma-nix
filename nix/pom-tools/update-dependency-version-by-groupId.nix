{
  writeShellApplication,
  xmlstarlet,
}:
writeShellApplication {
  name = "update-dependency-version-by-groupId";
  runtimeInputs = [xmlstarlet];
  text = builtins.readFile ./update-dependency-version-by-groupId.sh;
}
