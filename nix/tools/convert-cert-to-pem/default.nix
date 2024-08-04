{
  writeShellApplication,
  openssl
}:
writeShellApplication {
  name = "convert-cert-to-pem";
  runtimeInputs = [openssl];
  text = builtins.readFile ./convert-cert-to-pem.sh;
}
