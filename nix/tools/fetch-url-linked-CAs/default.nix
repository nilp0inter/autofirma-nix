{
  writeShellApplication,
  htmlq,
  openssl,
  coreutils,
  curl,
  jq,
  nix
}: writeShellApplication {
  name = "fetch-url-linked-CAs";
  runtimeInputs = [htmlq openssl coreutils curl nix jq];
  text = builtins.readFile ./fetch-url-linked-CAs.sh;
}

