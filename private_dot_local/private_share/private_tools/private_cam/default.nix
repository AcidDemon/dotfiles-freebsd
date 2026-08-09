{
  lib,
  pkgs,
}:
import ../mk-shell-app.nix {inherit lib pkgs;} {
  name = "cam";
  description = "ADB and scrcpy wrapper for using Android phones as a camera.";
  runtimeInputs = with pkgs; [android-tools scrcpy gnugrep];
  platforms = lib.platforms.linux;
  text = builtins.readFile ./cam.sh;
}
