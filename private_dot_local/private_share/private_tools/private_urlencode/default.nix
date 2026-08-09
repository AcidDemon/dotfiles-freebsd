{
  lib,
  pkgs,
}:
import ../mk-shell-app.nix {inherit lib pkgs;} {
  name = "urlencode";
  description = "URL-encodes a given string or input lines (UTF-8 compatible)";
  text = builtins.readFile ./urlencode.sh;
}
