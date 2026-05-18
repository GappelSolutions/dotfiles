{ pkgs, ... }:

let
  mountDev = pkgs.writeShellScript "mount-dev-smb" ''
    set -eu
    /bin/mkdir -p /Volumes/dev
    if ! /sbin/mount | /usr/bin/grep -q ' on /Volumes/dev '; then
      /sbin/mount_smbfs //guest:@dev/dev /Volumes/dev
    fi
  '';
  devClipboardBridge = pkgs.writeText "dev-clipboard-bridge.py" ''
    from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
    import subprocess

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            if self.path == "/health":
                self.send_response(204)
                self.end_headers()
                return
            if self.path != "/paste":
                self.send_error(404)
                return
            data = subprocess.check_output(["/usr/bin/pbpaste"])
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)

        def do_POST(self):
            if self.path != "/copy":
                self.send_error(404)
                return
            length = int(self.headers.get("Content-Length", "0"))
            data = self.rfile.read(length)
            subprocess.run(["/usr/bin/pbcopy"], input=data, check=True)
            self.send_response(204)
            self.end_headers()

        def log_message(self, format, *args):
            return

    ThreadingHTTPServer(("127.0.0.1", 19777), Handler).serve_forever()
  '';
in

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

  launchd.agents.dev-smb = {
    enable = true;
    config = {
      Label = "com.cgpp.dev-smb";
      ProgramArguments = [ "${mountDev}" ];
      RunAtLoad = true;
      StandardOutPath = "/tmp/dev-smb.log";
      StandardErrorPath = "/tmp/dev-smb.log";
    };
  };

  launchd.agents.dev-socks-tunnel = {
    enable = true;
    config = {
      Label = "com.cgpp.dev-socks-tunnel";
      ProgramArguments = [
        "/usr/bin/ssh"
        "-N"
        "-D"
        "127.0.0.1:1080"
        "-R"
        "127.0.0.1:19777:127.0.0.1:19777"
        "-o"
        "ExitOnForwardFailure=yes"
        "-o"
        "ServerAliveInterval=30"
        "-o"
        "ServerAliveCountMax=3"
        "dev"
      ];
      RunAtLoad = true;
      KeepAlive.NetworkState = true;
      StandardOutPath = "/tmp/dev-socks-tunnel.log";
      StandardErrorPath = "/tmp/dev-socks-tunnel.log";
    };
  };

  launchd.agents.dev-clipboard-bridge = {
    enable = true;
    config = {
      Label = "com.cgpp.dev-clipboard-bridge";
      ProgramArguments = [
        "/opt/homebrew/bin/python3"
        "${devClipboardBridge}"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/dev-clipboard-bridge.log";
      StandardErrorPath = "/tmp/dev-clipboard-bridge.log";
    };
  };
}
