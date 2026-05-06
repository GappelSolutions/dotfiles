{ ... }:

{
  launchd.agents.podman-machine = {
    enable = true;
    config = {
      Label = "com.podman.machine.default";
      ProgramArguments = [ "/opt/homebrew/bin/podman" "machine" "start" ];
      RunAtLoad = true;
      StandardOutPath = "/tmp/podman-machine.log";
      StandardErrorPath = "/tmp/podman-machine.log";
    };
  };
}
