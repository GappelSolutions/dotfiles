{ lib, rustPlatform }:

rustPlatform.buildRustPackage {
  pname = "lazyops";
  version = "0.1.0";

  src = ./.;

  cargoLock = {
    lockFile = ./Cargo.lock;
  };

  meta = with lib; {
    description = "A lazygit-style TUI for Azure DevOps work items";
    license = licenses.mit;
    maintainers = [ ];
  };
}
