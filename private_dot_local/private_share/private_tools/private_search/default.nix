{
  lib,
  pkgs,
}:
import ../mk-shell-app.nix {inherit lib pkgs;} {
  name = "search";
  description = "Search via different searchengines";
  runtimeInputs = with pkgs; [urlencode open];
  platforms = lib.platforms.linux;
  text = builtins.readFile ./search.sh;
}
