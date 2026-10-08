{ config, ... }:
let
  c = config.theming.colors;
  accent = c.blue;
  fg = color: { fg = color; };
  block = color: {
    fg = color;
    bg = color;
  };
  badge = color: {
    fg = c.bg;
    bg = color;
  };
  modeMain = color: badge color // { bold = true; };
  modeAlt = color: {
    fg = color;
    bg = c.black;
  };
  popup = {
    border = fg accent;
    title = fg c.fg;
  };
  list = {
    border = fg accent;
    active = {
      fg = c.magenta;
      bold = true;
    };
    inactive = fg c.brightBlack;
  };
in
{
  home-manager.sharedModules = [
    {
      programs.yazi = {
        enable = true;
        package = null; # installed system-wide

        theme = {
          mgr = {
            cwd = {
              fg = accent;
              bold = true;
            };
            find_keyword = {
              fg = c.yellow;
              italic = true;
            };
            find_position = {
              fg = c.magenta;
              bg = "reset";
              italic = true;
            };
            marker_copied = block c.green;
            marker_cut = block c.red;
            marker_marked = block c.yellow;
            marker_selected = block accent;
            count_copied = badge c.green;
            count_cut = badge c.red;
            count_selected = badge accent;
            border_symbol = "│";
            border_style = fg c.black;
          };

          indicator = {
            parent = badge c.brightBlack;
            current = badge accent;
            preview.underline = true;
          };

          tabs = {
            active = {
              fg = c.white;
              bg = c.black;
              bold = true;
            };
            inactive = {
              fg = c.brightBlack;
              bg = c.bg;
            };
          };

          mode = {
            normal_main = modeMain accent;
            normal_alt = modeAlt accent;
            select_main = modeMain c.yellow;
            select_alt = modeAlt c.yellow;
            unset_main = modeMain c.magenta;
            unset_alt = modeAlt c.magenta;
          };

          status = {
            sep_left = {
              open = "";
              close = "";
            };
            sep_right = {
              open = "";
              close = "";
            };
            perm_sep = fg c.brightBlack;
            perm_type = fg c.green;
            perm_read = fg c.yellow;
            perm_write = fg c.red;
            perm_exec = fg accent;
            progress_label = {
              fg = c.white;
              bold = true;
            };
            progress_normal = modeAlt accent;
            progress_error = modeAlt c.red;
          };

          pick = list;
          cmp = list;
          confirm = popup;
          tasks = popup // {
            hovered.underline = true;
          };

          input = popup // {
            value = fg c.white;
            selected = badge accent;
          };

          spot = popup // {
            tbl_col = fg accent;
            tbl_cell = badge c.magenta;
          };

          which = {
            border = fg accent;
            mask.bg = c.black;
            cand = fg accent;
            rest = fg c.brightBlack;
            desc = fg c.magenta;
            separator = "  ";
            separator_style = fg c.brightBlack;
          };

          notify = {
            title_info = fg accent;
            title_warn = fg c.yellow;
            title_error = fg c.red;
          };

          help = {
            border = fg accent;
            chord = fg accent;
            action = fg c.magenta;
            hovered = badge accent;
          };

          filetype.rules = [
            {
              url = "*/";
              fg = accent;
            }
            {
              mime = "**/image/*";
              fg = c.yellow;
            }
            {
              mime = "**/{audio,video}/*";
              fg = c.magenta;
            }
            {
              mime = "**/application/{zip,rar,7z*,tar,gzip,xz,zstd,bzip*,lzma,compress,archive,cpio,arj,xar,ms-cab*}";
              fg = c.red;
            }
            {
              mime = "**/application/pdf";
              fg = c.cyan;
            }
            {
              mime = "**/text/*";
              fg = c.fg;
            }
            {
              url = "*";
              is = "exec";
              fg = c.green;
            }
            {
              url = "*.{sh,py,rs}";
              fg = c.green;
            }
            {
              url = "*";
              fg = c.fg;
            }
          ];
        };
      };
    }
  ];
}
