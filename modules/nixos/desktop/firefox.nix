{ config, lib, ... }:
let
  # Status "default" seeds the value but leaves it editable in Settings/about:config.
  defaults = lib.mapAttrs (
    _: Value: {
      inherit Value;
      Status = "default";
    }
  );
in
{
  config = lib.mkIf config.desktop.enable {
    environment.sessionVariables = {
      MOZ_DBUS_REMOTE = "1";
      MOZ_GTK_TITLEBAR_DECORATION = "client";
      MOZ_DISABLE_SPLASH = "1";
    };

    programs.firefox = {
      enable = true;
      policies = {
        DisableTelemetry = true;
        DisableFirefoxStudies = true;
        Preferences = {
          "layers.acceleration.disabled" = {
            Value = false;
            Status = "locked";
          };
        }
        // defaults (
          {
            "browser.tabs.unloadOnLowMemory" = true;
            "gfx.canvas.accelerated.cache-size" = 512;
            "gfx.content.skia-font-cache-size" = 20;

            "dom.security.https_only_mode" = true;
            "privacy.globalprivacycontrol.enabled" = true;
            "network.dns.disablePrefetch" = true;
            "network.prefetch-next" = false;
            "network.http.speculative-parallel-limit" = 0;
            "media.eme.enabled" = true;
            "dom.forms.autocomplete.formautofill" = true;

            "browser.urlbar.suggest.bookmark" = false;
            "browser.urlbar.suggest.engines" = false;
            "browser.urlbar.suggest.history" = false;
            "browser.urlbar.suggest.openpage" = false;
            "browser.urlbar.suggest.searches" = false;
            "browser.urlbar.suggest.topsites" = false;
            "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
            "browser.newtabpage.activity-stream.feeds.topsites" = false;
            "browser.newtabpage.activity-stream.showSearch" = false;
            "browser.newtabpage.activity-stream.showSponsored" = false;
            "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
            "browser.newtabpage.activity-stream.telemetry" = false;
            "browser.newtabpage.activity-stream.feeds.telemetry" = false;
            "browser.discovery.enabled" = false;
            "browser.toolbars.bookmarks.visibility" = "always";
            "general.autoScroll" = true;
            "accessibility.typeaheadfind.flashBar" = 0;
            "pdfjs.enableAltText" = false;

            "browser.translations.enable" = false;
            "browser.ml.chat.enabled" = false;
            "browser.ml.linkPreview.enabled" = false;
            "extensions.ml.enabled" = false;
            "browser.tabs.groups.smart.enabled" = false;
          }
          // lib.genAttrs (map (f: "browser.ai.control.${f}") [
            "default"
            "linkPreviewKeyPoints"
            "pdfjsAltText"
            "sidebarChatbot"
            "smartTabGroups"
            "smartWindow"
            "translations"
          ]) (_: "blocked")
        );
      };
    };
  };
}
