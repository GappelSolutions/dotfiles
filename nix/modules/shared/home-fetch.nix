# Shell greeting (zsh initContent): `fetch`, built from nix/pkgs/fetch.
{ pkgs, ... }:

{
  home.packages = [ (pkgs.callPackage ../../pkgs/fetch/package.nix { }) ];
}
