{
  lib,
  pkgs,
}:
import ../mk-shell-app.nix {inherit lib pkgs;} {
  name = "open";
  description = "Open different uri formats with xdg-open";
  runtimeInputs = with pkgs; [xdg-utils git gnugrep coreutils];
  platforms = lib.platforms.linux;
  text = builtins.readFile ./open.sh;
}
