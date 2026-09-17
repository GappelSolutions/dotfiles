{ pkgs, ... }:

let
  t3-connect = pkgs.writeShellApplication {
    name = "t3-connect";
    runtimeInputs = with pkgs; [ nodejs coreutils findutils gnugrep gnused ];
    text = builtins.readFile ../../scripts/t3-connect;
  };
in
{
  home.packages = [ t3-connect ];
}
