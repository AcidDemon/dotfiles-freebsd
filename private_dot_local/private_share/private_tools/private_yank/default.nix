{
  lib,
  pkgs,
}:
import ../mk-shell-app.nix {inherit lib pkgs;} {
  name = "yank";
  description = "Wrapper around common clipboards taking stdin, a file or a (multi word) string";
  runtimeInputs = with pkgs; [wl-clipboard xclip];
  text = builtins.readFile ./yank.sh;
}
