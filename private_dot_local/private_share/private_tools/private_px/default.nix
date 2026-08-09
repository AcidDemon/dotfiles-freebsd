{
  lib,
  pkgs,
}:
import ../mk-shell-app.nix {inherit lib pkgs;} {
  name = "px";
  description = "Paste-X - Read or upload text to different pastebins";
  runtimeInputs = with pkgs; [curl coreutils netcat yank];
  text = builtins.readFile ./px.sh;
}
