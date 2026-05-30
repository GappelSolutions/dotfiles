{ ... }:

{
  home.file.".local/bin/wife-help" = {
    source = ../../../wife/.local/bin/wife-help;
    executable = true;
  };

  home.file."Documents/wife_cheatsheet.md".source =
    ../../../wife/Documents/wife_cheatsheet.md;
}
