{
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = true;
  };

  system.activationScripts.postActivation.text = ''
    defaults -currentHost delete -g com.apple.keyboard.modifiermapping.0-0-0 2>/dev/null || true
  '';
}
