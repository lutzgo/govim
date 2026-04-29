# Thin variant-selector wrapper for home-manager.
# Gives downstream configs a clean interface:
#
#   programs.my-nvim = {
#     enable = true;
#     variant = "maximal";   # minimal | markdown | default | maximal
#   };
#
# This module does NOT configure nvim – it only installs the chosen
# package. All nvim options live inside the flake's own modules.
{ self }: {
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.my-nvim;
in {
  options.programs.my-nvim = {
    enable = lib.mkEnableOption "govim – personal multi-variant Neovim";

    variant = lib.mkOption {
      type = lib.types.enum ["minimal" "markdown" "default" "maximal"];
      default = "default";
      description = ''
        Which govim variant to install.
          minimal   – server-friendly, no LSP, runnable via `nix run`
          markdown  – prose/notes: render-markdown, spellcheck, soft wrap
          default   – daily-driver IDE (LSP, completion, git)
          maximal   – kitchen sink: all of the above plus DAP and extras
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [self.packages.${pkgs.system}.${cfg.variant}];

    # NOTE: impermanence is managed outside this module.
    # Add the following to your impermanence config so undo history,
    # sessions, and shada survive reboots:
    #
    #   home.persistence."/persist/home/<user>" = {
    #     directories = [
    #       ".local/share/nvim"
    #       ".local/state/nvim"
    #     ];
    #   };
  };
}
