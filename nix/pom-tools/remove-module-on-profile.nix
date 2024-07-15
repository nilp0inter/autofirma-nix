{
  writeShellApplication,
  xmlstarlet,
}:
writeShellApplication {
  name = "remove-module-on-profile";
  runtimeInputs = [xmlstarlet];
  text = builtins.readFile ./remove-module-on-profile.sh;
}

