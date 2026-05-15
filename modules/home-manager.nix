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
      type = lib.types.enum ["minimal" "default"];
      default = "default";
      description = ''
        Which govim variant to install.
          minimal  – server-friendly, no LSP, runnable via `nix run`
          default  – daily driver: IDE, org/PKM, markdown, all languages
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
