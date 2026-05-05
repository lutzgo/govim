# Maximal: the kitchen sink. Imports default and adds DAP, more
# languages, AI assist, debugging, extra visuals.
#
# Caveat: this builds a *lot*. Use the nvf cachix cache when iterating.
{
  imports = [./default.nix];

  vim = {
    languages = {
      html.enable = true;
      css.enable = true;
      yaml.enable = true;
      toml.enable = true;
      json.enable = true;
      sql.enable = true;
      terraform.enable = true;
      hcl.enable = true;
    };

    # ---- Debugging --------------------------------------------------
    debugger.nvim-dap = {
      enable = true;
      ui.enable = true;
    };

    # ---- AI assistance (pick one when you're ready) -----------------
    # Don't enable more than one – they fight over keymaps/signcolumn.
    # assistant.codecompanion-nvim.enable = true;
    # assistant.copilot.enable = true;

    # ---- Extras -----------------------------------------------------
    utility.smart-splits.enable = true;
    # fidget-nvim removed: noice handles LSP progress notifications now.
    git.neogit.enable = true;
    session.nvim-session-manager.enable = true;
  };
}
