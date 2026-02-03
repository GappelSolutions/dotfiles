{ lib, rustPlatform }:

rustPlatform.buildRustPackage {
  pname = "zellij-welcome";
  version = "0.1.0";

  src = ./.;

  cargoLock = {
    lockFile = ./Cargo.lock;
  };

  meta = with lib; {
    description = "TUI session picker for Zellij";
    license = licenses.mit;
    maintainers = [ ];
  };
}
