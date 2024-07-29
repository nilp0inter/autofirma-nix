{
  writeShellApplication,
  xmlstarlet,
  jq,
}: writeShellApplication {
  name = "trusted-providers";
  runtimeInputs = [xmlstarlet jq];
  text = builtins.readFile ./trusted-providers.sh;
}
