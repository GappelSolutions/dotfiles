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
    default_tool = "claude"
    yolo_mode_default = true
    live_send_exit_chord = "C-q"
    live_send_leader = "C-b"
    new_session_attach_mode = "live_send"
    default_attach_mode = "live_send"
    click_action = "live_send"
    confirm_before_quit = false

    [session.custom_agents]
    claude = "claude --verbose"
    omp = "omp"

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

  # Single source for the llama-swap box address. Plain LAN IP: the box has no
  # DNS name, and it is reachable from macOS and WSL alike.
  nixHitchOneUrl = "http://172.25.65.31:8080/v1";

  # Local llama-swap box (nix-hitch-one, gfx1201). `agentic` is Qwen3.8-27B Q4_K_XL,
  # `chat` is the fast MoE. The API is unauthenticated and reachable only from
  # the allowlisted LAN range, hence `auth: none`.
  ompModelsSeed = pkgs.writeText "omp-models.yml" ''
    providers:
      nix-hitch-one:
        baseUrl: ${nixHitchOneUrl}
        api: openai-completions
        auth: none
        models:
          - id: agentic
            name: Qwen3.8-27B Q4_K_XL (nix-hitch-one)
            reasoning: true
            input: [text]
            contextWindow: 131072
            maxTokens: 32768
            cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 }
          - id: chat
            name: Qwen3.6-35B-A3B Q4_K_XL (nix-hitch-one)
            reasoning: true
            input: [text]
            contextWindow: 262144
            maxTokens: 32768
            cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 }
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

  # T3 Code has no provider of its own: it shells out to opencode, so the local
  # box is registered here and surfaced in T3 as the `nix-hitch-one/*` slugs.
  # openai-compatible talks /v1/chat/completions, which is what llama-swap
  # fronts; no apiKey, the server is unauthenticated behind its firewall.
  xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    provider.nix-hitch-one = {
      npm = "@ai-sdk/openai-compatible";
      name = "nix-hitch-one (llama-swap)";
      options.baseURL = nixHitchOneUrl;
      models = {
        agentic = {
          name = "Qwen3.8-27B Q4_K_XL";
          limit = { context = 131072; output = 32768; };
        };
        chat = {
          name = "Qwen3.6-35B-A3B Q4_K_XL";
          limit = { context = 262144; output = 32768; };
        };
      };
    };
  };

  home.activation.bootstrapOmpModels =
    config.lib.dag.entryAfter [ "writeBoundary" ] ''
      config_dir="$HOME/.omp/agent"
      config_file="$config_dir/models.yml"

      if [ ! -e "$config_file" ]; then
        mkdir -p "$config_dir"
        install -m 0600 ${ompModelsSeed} "$config_file"
      fi
    '';
}
