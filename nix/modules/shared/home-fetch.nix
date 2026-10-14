# areofyl/fetch: spinning 3D distro logo, shell greeting (zsh initContent).
# Defaults (no ~/.config/fetch/config), only the height is set by the caller.
{ pkgs, ... }:

{
  home.packages = [
    (pkgs.fetch.overrideAttrs (old: {
      # On exit, put the cursor under the last drawn row instead of under the whole canvas
      patches = (old.patches or [ ]) ++ [ ./patches/fetch-trim-trailing-rows.patch ];
    }))
  ];
}
