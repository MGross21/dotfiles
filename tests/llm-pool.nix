{ pkgs, lib, ... }:
let
  port = 8180;
  fakeModel = name: addr: {
    services.nginx = {
      enable = true;
      additionalModules = [ pkgs.nginxModules.echo ];
      virtualHosts.fake-llm = {
        listen = [
          {
            inherit addr port;
          }
        ];
        locations."/".extraConfig = "echo_sleep 2; echo ${name};";
        locations."/v1/unavailable".extraConfig =
          if name == "pc" then "return 503;" else "echo_read_request_body; echo ${name};";
      };
    };
  };
in
{
  name = "llm-pool";

  nodes = {
    pc = {
      imports = [ (fakeModel "pc" "0.0.0.0") ];
      networking.firewall.allowedTCPPorts = [ port ];
    };

    dell =
      { nodes, ... }:
      {
        imports = [
          ../modules/shared/hosts.nix
          ../modules/nixos/services/llm
          (fakeModel "dell" "127.0.0.1")
        ];
        options = {
          desktop.idle.listeners = lib.mkOption {
            type = lib.types.listOf lib.types.attrs;
            default = [ ];
          };
          alerts.units = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
          };
        };
        config = {
          llm = {
            enable = true;
            borrowFrom = "pc";
            borrowAddress = nodes.pc.networking.primaryIPAddress;
          };
          services.llama-cpp.enable = lib.mkForce false;
        };
      };
  };

  testScript =
    { nodes, ... }:
    let
      inherit (nodes.dell.llm) port proxyPort;
    in
    ''
      import time

      def ask(n):
          url = "localhost:${toString proxyPort}/v1/chat/completions"
          return dell.succeed(f"curl -sf --parallel --parallel-immediate -d '{{}}' {' '.join([url] * n)}").split()

      def timed(n):
          start = time.monotonic()
          return ask(n), time.monotonic() - start

      start_all()
      pc.wait_for_open_port(${toString port})
      dell.wait_for_open_port(${toString proxyPort})

      with subtest("busy pc overflows to dell"):
          got = ask(3)
          assert sorted(got) == ["dell", "dell", "pc"], got

      with subtest("idle pc takes a single request"):
          assert ask(1) == ["pc"]

      with subtest("each request wakes pc"):
          accepted = "systemctl show -P NAccepted llm-wake.socket"
          before = int(dell.succeed(accepted))
          ask(1)
          dell.wait_until_succeeds(f"[ $({accepted}) -gt {before} ]")
          dell.fail("systemctl is-failed --quiet 'llm-wake@*'")

      with subtest("503 from pc retries a large body on dell"):
          dell.succeed("head -c 524288 /dev/zero | tr '\\0' x > /tmp/body")
          got = dell.succeed("curl -sf --data-binary @/tmp/body localhost:${toString proxyPort}/v1/unavailable").split()
          assert got == ["dell"], got

      with subtest("refused pc falls through to dell"):
          pc.succeed("systemctl stop nginx")
          assert ask(2) == ["dell", "dell"]

      with subtest("unreachable pc falls through to dell, then is skipped"):
          pc.crash()
          dell.succeed("sleep 31")
          got, first = timed(1)
          assert got == ["dell"] and first < 8, (got, first)
          got, second = timed(1)
          assert got == ["dell"] and second < 4, (got, second)
    '';
}
