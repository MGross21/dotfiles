{ pkgs, ... }:
{
  # soft-mixer stops PipeWire writing ALSA capture gain; mic-gain.service owns it.
  services.pipewire.wireplumber.extraConfig."51-mic-gain" = {
    "monitor.alsa.rules" = [
      {
        matches = [ { "node.name" = "alsa_input.pci-0000_00_1f.3.analog-stereo"; } ];
        actions.update-props."api.alsa.soft-mixer" = true;
      }
    ];
  };

  # filter-chain does not chain nodes by array order; without explicit links the graph emits silence.
  services.pipewire.extraConfig.pipewire."99-mic-highpass" = {
    "context.modules" = [
      {
        name = "libpipewire-module-filter-chain";
        args = {
          "node.description" = "Mic (filtered)";
          "media.name" = "Mic (filtered)";
          "filter.graph" = {
            nodes = [
              {
                type = "builtin";
                name = "mix";
                label = "mixer";
                control = {
                  "Gain 1" = 0.5;
                  "Gain 2" = 0.5;
                };
              }
              {
                type = "builtin";
                name = "hp1";
                label = "bq_highpass";
                control = {
                  "Freq" = 100.0;
                  "Q" = 0.707;
                };
              }
              {
                type = "builtin";
                name = "hp2";
                label = "bq_highpass";
                control = {
                  "Freq" = 100.0;
                  "Q" = 0.707;
                };
              }
            ];
            links = [
              {
                output = "mix:Out";
                input = "hp1:In";
              }
              {
                output = "hp1:Out";
                input = "hp2:In";
              }
            ];
            inputs = [
              "mix:In 1"
              "mix:In 2"
            ];
            outputs = [ "hp2:Out" ];
          };
          "capture.props" = {
            "node.name" = "capture.mic_filtered";
            "node.passive" = true;
            "audio.position" = [
              "FL"
              "FR"
            ];
            "target.object" = "alsa_input.pci-0000_00_1f.3.analog-stereo";
          };
          "playback.props" = {
            "node.name" = "mic_filtered";
            "media.class" = "Audio/Source";
            "audio.position" = [ "MONO" ];
          };
        };
      }
    ];
  };

  systemd.services.mic-gain = {
    description = "Pin ALC1220 internal mic analog gain";
    wantedBy = [
      "multi-user.target"
      "post-resume.target"
    ];
    after = [
      "sound.target"
      "post-resume.target"
    ];
    serviceConfig.Type = "oneshot";
    # -c PCH: card index is unstable, the NVIDIA HDA controller also registers.
    script = ''
      ${pkgs.alsa-utils}/bin/amixer -c PCH -q sset 'Internal Mic Boost' 0
      ${pkgs.alsa-utils}/bin/amixer -c PCH -q sset 'Capture' 97%
    '';
  };
}
