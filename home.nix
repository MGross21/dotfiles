{ pkgs, ... }:

{
  home.stateVersion = "25.11";

  # HOME PACKAGES
  home.packages = with pkgs; [
    # IDEs and Editors
    neovim
    
    # Extra utilities
    ripgrep
    fd
    bat
    eza
    fzf
    zoxide
  ];

  # DOTFILES
  home.file = {
    # TODO: Uncomment and configure these paths to sync your config files
    # You can either:
    # 1. Symlink existing configs: ".config/hyprland" = { source = ../path/to/hyprland; };
    # 2. Create new configs inline (see Zsh config below)
    
    # ".config/hyprland".source = ../config/hyprland;
    # ".config/nvim".source = ../config/neovim;
    # ".config/waybar".source = ../config/waybar;
  };

  # BASH
  programs.bash = {
    enable = true;
    bashrcExtra = ''
      # Custom bash configurations here
    '';
  };

  # ALACRITTY
  programs.alacritty = {
    enable = false;  # Using Ghostty instead
    # settings = {
    #   window.opacity = 0.95;
    #   font.size = 12;
    # };
  };

  # ZSH
  programs.zsh = {
    enable = true;
    autocd = true;
    history = {
      size = 10000;
      save = 10000;
      ignoreDups = true;
      ignoreSpace = true;
    };
    
    shellAliases = {
      # Utility aliases
      ls = "eza -la";
      ll = "eza -lh";
      lt = "eza --tree";
      cat = "bat";
      grep = "rg";
      find = "fd";
      
      # Git aliases
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git log --oneline";
      
      # System aliases
      sysupdate = "sudo nixos-rebuild switch --flake .";  # After moving to NixOS
      
      # TODO: Add your custom aliases here
    };

    initExtra = ''
      # Enable fzf key bindings
      source <(fzf --bash)
      
      # Zoxide initialization
      eval "$(zoxide init zsh)"
      
      # TODO: Add custom zsh configurations here
    '';

    plugins = [
      {
        name = "zsh-syntax-highlighting";
        src = "${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting";
      }
      {
        name = "zsh-autosuggestions";
        src = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions";
      }
      {
        name = "zsh-history-substring-search";
        src = "${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search";
      }
    ];
  };

  # GIT
  programs.git = {
    enable = true;
    userEmail = "your-email@example.com";  # TODO: Update
    userName = "Your Name";  # TODO: Update
    extraConfig = {
      core.editor = "nvim";
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

  # TMUX
  programs.tmux = {
    enable = true;
    prefix = "C-a";
    baseIndex = 1;
    newSessionPath = "~";
    escapeTime = 0;
    extraConfig = ''
      set-option -g mouse on
      set-option -g default-terminal "screen-256color"
      
      # Pane navigation
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R
      
      # TODO: Add your tmux configuration
    '';
  };

  # NEOVIM
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    # TODO: Add your Neovim configuration
    # You can either source an existing init file or configure inline
    # extraConfig = ''
    #   " Your nvim config here
    # '';
  };

  # GPG AGENT
  services.gpg-agent = {
    enable = false;  # Managed by gnome-keyring typically
    # extraConfig = ''
    #   '' ;
  };

  # SYSTEMD USER SERVICES
  systemd.user.services = {
    # Example service configuration
    # myservice = {
    #   Unit.Description = "My User Service";
    #   Install.WantedBy = [ "graphical-session.target" ];
    #   Service = {
    #     Type = "simple";
    #     ExecStart = "${pkgs.mypackage}/bin/mycommand";
    #   };
    # };
  };
}