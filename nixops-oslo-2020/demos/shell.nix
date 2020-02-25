{
  pkgs ? (import <nixpkgs> {})
}:

with pkgs;

pkgs.mkShell {
  name = "nixops-environment";
  buildInputs = [ nixopsUnstable ];
}
