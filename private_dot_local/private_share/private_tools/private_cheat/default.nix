{
  lib,
  pkgs,
}:
import ../mk-shell-app.nix {inherit lib pkgs;} {
  name = "cheat";
  description = "Cheat sheets in the terminal";
  runtimeInputs = with pkgs; [curl urlencode];
  text = builtins.readFile ./cheat.sh;
}
