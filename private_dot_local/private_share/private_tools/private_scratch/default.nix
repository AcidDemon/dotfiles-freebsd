{
  lib,
  pkgs,
}:
import ../mk-shell-app.nix {inherit lib pkgs;} {
  name = "scratch";
  description = "Terminal scratchpad";
  runtimeInputs = with pkgs; [coreutils];
  text = builtins.readFile ./scratch.sh;
}
