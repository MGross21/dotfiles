{ ... }:
{
  home-manager.sharedModules = [
    (
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        # Link target is the working tree, so managed config stays writable in place.
        fromRepo = path: config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.dir}/${path}";

        configEntries = [
          "alacritty.toml"
          "dunst"
          "hypr"
          "liquid-glass"
          "ly"
          "neofetch"
          "README.md"
        ];

        vscodeTheme = pkgs.fetchFromGitHub {
          owner = "MGross21";
          repo = "vscode-tomorrow-night-burns";
          rev = "fa722503c82a455c4131071a0b101aeecbb68313";
          sha256 = "05g6a9nr8nqf2aj4gcvblxpp8i86n12y41b3hvfknjgijxliip2b";
        };
      in
      {
        xdg.configFile = lib.genAttrs configEntries (name: {
          source = fromRepo ".config/${name}";
        });

        home.file = {
          "Pictures/wallpapers".source = fromRepo "Pictures/wallpapers";
          "Pictures/profiles".source = fromRepo "Pictures/profiles";
          ".vscode/extensions/alii.vscode-tomorrow-night-burns-master".source = vscodeTheme;
        };

        # VS Code rewrites argv.json in place, so it cannot be a store symlink.
        home.activation.vscodeArgvJson = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          argv="${config.xdg.configHome}/Code/argv.json"
          run rm -f "$argv"
          run mkdir -p "$(dirname "$argv")"
          run install -m 0600 ${pkgs.writeText "vscode-argv.json" ''
            {
              "password-store": "gnome-libsecret"
            }
          ''} "$argv"
        '';
      }
    )
  ];
}
