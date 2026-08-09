{
  lib,
  pkgs,
}:
import ../mk-shell-app.nix {inherit lib pkgs;} {
  name = "ebook2audio";
  description = "Convert ebooks to audiobooks.";
  runtimeInputs = with pkgs; [
    piper-tts
    calibre
    coreutils
    findutils
    xdg-utils
  ];
  platforms = lib.platforms.linux;
  text = builtins.readFile ./ebook2audio.sh;
}
