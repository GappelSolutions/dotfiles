{ lib, rustPlatform, makeWrapper, cotp, keyutils }:

rustPlatform.buildRustPackage {
  pname = "twofa";
  version = "0.1.0";

  src = ./.;

  cargoLock = {
    lockFile = ./Cargo.lock;
  };

  nativeBuildInputs = [ makeWrapper ];

  # cotp is the encrypted store, keyctl caches its password in the kernel user keyring.
  postInstall = ''
    wrapProgram $out/bin/2fa --prefix PATH : ${lib.makeBinPath [ cotp keyutils ]}
  '';

  meta = with lib; {
    description = "TOTP picker on top of cotp's database";
    license = licenses.mit;
    mainProgram = "2fa";
    platforms = platforms.linux;
  };
}
