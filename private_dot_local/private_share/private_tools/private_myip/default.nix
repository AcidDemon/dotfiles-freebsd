{
  lib,
  pkgs,
}:
import ../mk-shell-app.nix {inherit lib pkgs;} {
  name = "myip";
  description = "Prints your public IP (IPv4/IPv6) using DNS";
  runtimeInputs = with pkgs; [bind coreutils];
  text = builtins.readFile ./myip.sh;
}
