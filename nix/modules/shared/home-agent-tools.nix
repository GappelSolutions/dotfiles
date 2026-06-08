{ config, pkgs, ... }:

let
  agentOfEmpiresSeed = pkgs.writeText "agent-of-empires-config.toml" ''
    default_profile = ""

    [theme]
    name = "deep-ocean"
    color_mode = "truecolor"
    idle_decay_minutes = 0

    [telemetry]
    enabled = false

    [session]
    default_tool = "omp"
    yolo_mode_default = true
    live_send_exit_chord = "C-q"
    live_send_leader = "C-b"
    new_session_attach_mode = "live_send"
    default_attach_mode = "live_send"
    click_action = "live_send"
    confirm_before_quit = false

    [session.custom_agents]
    omp = "omp \"/skill:caveman ultra\""

    [session.agent_detect_as]
    omp = "pi"

    [session.agent_acp_cmd]
    omp = "omp acp"

    [diff]
    split_view = true

    [app_state]
    has_seen_welcome = true
    has_responded_to_telemetry = true
  '';
in
{
  home.activation.bootstrapAgentOfEmpiresConfig =
    config.lib.dag.entryAfter [ "writeBoundary" ] ''
      config_dir="$HOME/.config/agent-of-empires"
      config_file="$config_dir/config.toml"

      if [ ! -e "$config_file" ]; then
        mkdir -p "$config_dir"
        install -m 0600 ${agentOfEmpiresSeed} "$config_file"
      fi
    '';
}
