{
  lib,
  pkgs,
}:
import ../mk-shell-app.nix {inherit lib pkgs;} {
  name = "clone";
  description = "Wrapper around git clone";
  runtimeInputs = with pkgs; [git];
  text = builtins.readFile ./clone.sh;
}
