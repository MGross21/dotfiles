{ config, lib, ... }:
let
  profile = config.theming.firefoxProfile;
  c = config.theming.colors;
  inherit (config.theming) accent;
  vars =
    attrs:
    lib.concatStrings (lib.mapAttrsToList (name: value: "  --${name}: ${value} !important;\n") attrs);
in
{
  home-manager.sharedModules = lib.mkIf (profile != null) [
    (
      { config, ... }:
      {
        programs.firefox = {
          enable = true;
          package = null;
          configPath = "${config.xdg.configHome}/mozilla/firefox";
          profiles.default = {
            path = profile;
            isDefault = true;
            userChrome = ''
              :root {
              ${
                vars {
                  toolbox-text-color = c.fg;
                  toolbox-text-color-inactive = c.fg;
                  tab-loading-fill = accent;
                  toolbarfield-background-color = c.bg;
                  toolbarfield-focus-background-color = c.bg;
                  toolbarfield-color = c.fg;
                  toolbarfield-focus-color = c.fg;
                  toolbarfield-focus-border-color = accent;
                  focus-outline-color = accent;
                  urlbarView-highlight-background = c.selection;
                  arrowpanel-background = c.black;
                  arrowpanel-color = c.fg;
                  arrowpanel-border-color = c.brightBlack;
                  sidebar-background-color = c.bg;
                  sidebar-text-color = c.fg;
                }
              }}
              body {
                background: ${c.bg} !important;
                color: ${c.fg} !important;
              }
              #nav-bar,
              #PersonalToolbar {
                background: ${c.black} !important;
                color: ${c.fg} !important;
              }
              #navigator-toolbox {
                border-bottom: 1px solid ${c.brightBlack} !important;
              }
              .tab-background[selected] {
                background: linear-gradient(${c.black}, ${c.black}) padding-box, linear-gradient(${accent}, ${accent}) border-box !important;
              }
            '';
            userContent = ''
              @-moz-document url("about:newtab"), url("about:home") {
                :root {
              ${
                vars {
                  newtab-background-color = c.bg;
                  newtab-background-color-secondary = c.black;
                  newtab-text-primary-color = c.fg;
                }
              }  }
              }
            '';
          };
        };
      }
    )
  ];
}
