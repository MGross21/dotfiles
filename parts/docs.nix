{ lib, self, ... }:
let
  owner = "MGross21";
  repoName = "dotfiles";
  repo = "https://github.com/${owner}/${repoName}";
  site = "https://${lib.toLower owner}.github.io/${repoName}/";
  rev = self.shortRev or self.dirtyShortRev or "unknown";
  root = "${toString self}/";
  msi = self.nixosConfigurations.msi;
  inherit (msi.config) theming;
  hosts =
    lib.filterAttrs (name: _: !lib.hasPrefix "installer" name) self.nixosConfigurations
    // self.darwinConfigurations;

  allSections = [
    {
      id = "shared";
      title = "Shared";
      dirs = [ "modules/shared" ];
      inherit (msi) options;
    }
    {
      id = "system";
      title = "NixOS and nix-darwin";
      dirs = [ "modules/system" ];
      inherit (msi) options;
    }
    {
      id = "nixos";
      title = "NixOS";
      dirs = [
        "modules/nixos"
        "hosts"
      ];
      inherit (msi) options;
    }
    {
      id = "darwin";
      title = "nix-darwin";
      dirs = [ "modules/darwin" ];
      options = self.darwinConfigurations.mac.options;
    }
    {
      id = "home";
      title = "Home Manager";
      dirs = [ "modules/home" ];
      options = self.homeConfigurations."${msi.config.user.name}@wsl".options;
    }
  ];

  relative = decl: lib.removePrefix root (toString decl);
  ownedBy = dirs: decls: lib.any (f: lib.any (d: lib.hasPrefix "${d}/" (relative f)) dirs) decls;
  docOptions =
    s:
    lib.filter (o: o.visible && !o.internal && ownedBy s.dirs o.declarations) (
      lib.optionAttrSetToDocList s.options
    );
  sections = lib.filter (s: docOptions s != [ ]) allSections;

  hostValue =
    cfg: loc:
    let
      opt = lib.attrByPath loc null cfg.options;
      setByHost =
        lib.isOption opt
        && lib.any (d: lib.hasPrefix "${root}hosts/" (toString d.file)) opt.definitionsWithLocations;
      pretty = lib.generators.toPretty { } opt.value;
      result = builtins.tryEval (builtins.deepSeq pretty pretty);
    in
    if !setByHost then
      null
    else if result.success then
      result.value
    else
      "<unevaluable>";

  hostValues = lib.listToAttrs (
    lib.concatMap (
      s:
      map (opt: {
        inherit (opt) name;
        value = lib.filterAttrs (_: v: v != null) (lib.mapAttrs (_: cfg: hostValue cfg opt.loc) hosts);
      }) (docOptions s)
    ) (lib.filter (s: s.id != "home") sections)
  );
in
{
  perSystem =
    { pkgs, system, ... }:
    let
      optionsJSON =
        { dirs, options, ... }:
        (pkgs.nixosOptionsDoc {
          inherit options;
          warningsAreErrors = false;
          transformOptions =
            opt:
            opt
            // {
              visible = opt.visible && ownedBy dirs opt.declarations;
              declarations = map (
                d:
                let
                  f = relative d;
                in
                {
                  name = f;
                  url = "${repo}/blob/main/${f}";
                }
              ) opt.declarations;
            };
        }).optionsJSON;

      sectionsFile = pkgs.writeText "sections.json" (
        builtins.toJSON (
          map (s: {
            inherit (s) id title;
            file = "${optionsJSON s}/share/doc/nixos/options.json";
          }) sections
        )
      );
      hostsFile = pkgs.writeText "hosts.json" (
        builtins.toJSON (lib.filterAttrs (_: v: v != { }) hostValues)
      );

      fontFiles = [
        {
          font = theming.fonts.sansSerif;
          weights = {
            Regular = 400;
            Medium = 500;
            SemiBold = 600;
            Bold = 700;
          };
        }
        {
          font = theming.fonts.monospace;
          weights = {
            Regular = 400;
            Medium = 500;
          };
        }
      ];
      fileName = font: weight: "${lib.replaceStrings [ " " ] [ "" ] font.name}-${weight}";
      fonts =
        pkgs.runCommand "docs-fonts"
          {
            nativeBuildInputs = [
              (pkgs.python3.withPackages (p: [
                p.fonttools
                p.brotli
              ]))
            ];
          }
          ''
            mkdir -p $out
            ${lib.concatMapStrings (
              { font, weights }:
              lib.concatMapStrings (w: ''
                src=$(find ${font.package}/share/fonts -name '${fileName font w}.*' | head -1)
                pyftsubset "$src" --flavor=woff2 --layout-features='*' \
                  --unicodes='U+0000-024F,U+2000-206F,U+2190-21FF,U+2200-22FF,U+2500-25FF' \
                  --output-file=$out/${fileName font w}.woff2
              '') (lib.attrNames weights)
            ) fontFiles}
          '';

      palette = pkgs.writeText "palette.css" (
        let
          c = theming.colors;
          channels =
            hex:
            map (i: lib.fromHexString (lib.substring i 2 (lib.removePrefix "#" hex))) [
              0
              2
              4
            ];
          triplet = cs: lib.concatMapStringsSep " " toString cs;
          rgb = hex: triplet (channels hex);
          mix =
            a: b: t:
            triplet (lib.zipListsWith (x: y: (x * (100 - t) + y * t) / 100) (channels a) (channels b));
        in
        lib.concatMapStrings (
          { font, weights }:
          lib.concatStrings (
            lib.mapAttrsToList (w: n: ''
              @font-face { font-family: "${font.name}"; font-weight: ${toString n}; font-display: swap; src: url("fonts/${fileName font w}.woff2") format("woff2"); }
            '') weights
          )
        ) fontFiles
        + ''
          :root {
            --d-bg: ${c.bg};
            --d-fg: ${c.fg};
            --d-surface: ${c.black};
            --d-accent: ${theming.accent};
            --l-bg: ${c.brightWhite};
            --l-fg: ${c.bg};
            --d-rgb-bg: ${rgb c.bg};
            --d-rgb-fg: ${rgb c.fg};
            --d-rgb-surface: ${rgb c.black};
            --l-rgb-bg: ${rgb c.brightWhite};
            --l-rgb-fg: ${rgb c.bg};
            --l-rgb-surface: ${mix c.brightWhite c.bg 10};
            --md-text-font: "${theming.fonts.sansSerif.name}";
            --md-code-font: "${theming.fonts.monospace.name}";
          }
        ''
      );

      config = (pkgs.formats.toml { }).generate "zensical.toml" {
        project = {
          site_name = "${repoName} options";
          site_url = site;
          repo_url = repo;
          repo_name = "${owner}/${repoName}";
          copyright = ''Built from <a href="${repo}/commit/${rev}"><code>${rev}</code></a>'';
          nav = [ { Overview = "index.md"; } ] ++ map (s: { ${s.title} = "${s.id}.md"; }) sections;
          extra_css = [
            "assets/palette.css"
            "assets/style.css"
          ];
          extra_javascript = [ "assets/app.js" ];
          theme = {
            language = "en";
            font = false;
            icon.repo = "simple/github";
            features = [
              "content.code.copy"
              "navigation.footer"
              "navigation.instant"
              "navigation.instant.prefetch"
              "navigation.top"
              "navigation.tracking"
              "search.highlight"
              "toc.follow"
            ];
            palette = [
              {
                media = "(prefers-color-scheme)";
                toggle = {
                  icon = "lucide/sun-moon";
                  name = "Switch to light mode";
                };
              }
              {
                media = "(prefers-color-scheme: light)";
                scheme = "default";
                primary = "custom";
                accent = "custom";
                toggle = {
                  icon = "lucide/sun";
                  name = "Switch to dark mode";
                };
              }
              {
                media = "(prefers-color-scheme: dark)";
                scheme = "slate";
                primary = "custom";
                accent = "custom";
                toggle = {
                  icon = "lucide/moon";
                  name = "Switch to system preference";
                };
              }
            ];
          };
          markdown_extensions = {
            attr_list = { };
            md_in_html = { };
            tables = { };
            toc = {
              permalink = true;
              toc_depth = 3;
            };
            "pymdownx.highlight" = { };
            "pymdownx.inlinehilite" = { };
            "pymdownx.superfences" = { };
          };
        };
      };
    in
    {
      packages = lib.mkIf (system == "x86_64-linux") {
        docs =
          pkgs.runCommand "dotfiles-docs"
            {
              nativeBuildInputs = [
                pkgs.python3
                pkgs.zensical
              ];
            }
            ''
              mkdir -p docs/assets
              python3 ${../docs/render.py} ${sectionsFile} ${hostsFile} docs
              cp -r ${fonts} docs/assets/fonts
              cp ${palette} docs/assets/palette.css
              cp ${../docs/style.css} docs/assets/style.css
              cp ${../docs/app.js} docs/assets/app.js
              cp ${config} zensical.toml
              zensical build --strict
              cp -r site $out
            '';
      };
    };
}
