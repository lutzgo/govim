# Stylix / base16 theme override.
#
# govim's `common.nix` hardcodes a catppuccin-mocha colorscheme so that a bare
# `nix run github:lutzgo/govim` looks right with no host involvement. A host
# that already owns a palette — Stylix on a clan machine — needs to replace it.
#
# That override used to live downstream, in clanarchy's `modules/users/lgo.nix`:
# a `lib.mkForce` on `vim.theme`, a base16-nvim `extraPlugins` entry, and a
# hand-written `luaConfigRC` block interpolating sixteen colors. Three pieces of
# govim's internals, duplicated in a repo that cannot see when they change.
#
# It lives here now, next to the theme it overrides, so a colorscheme change in
# `common.nix` and its Stylix counterpart move together. `checks.stylix` builds
# this module against a dummy palette, which makes the contract tested rather
# than merely documented.
#
# Usage from a Stylix host:
#
#   programs.nvf.settings = {
#     imports = [
#       "${inputs.govim}/modules/common.nix"
#       "${inputs.govim}/modules/variants/default.nix"
#       "${inputs.govim}/modules/stylix.nix"
#     ];
#     govim.stylix = {
#       enable = true;
#       colors = config.lib.stylix.colors;
#     };
#   };
#
# Or, preferring the stable flake attributes over interpolated store paths:
#
#   imports = with inputs.govim.nvfModules; [common default stylix];
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.govim.stylix;

  # base16-nvim wants hex without the leading '#'. Stylix's colour attrset
  # provides exactly that under the bare `baseXX` names (it also carries
  # `baseXX-hex`, `withHashtag`, and a functor for template rendering — hence
  # `types.raw`, which passes the whole thing through untouched instead of
  # trying to merge or type-check a functor attrset).
  names = [
    "base00"
    "base01"
    "base02"
    "base03"
    "base04"
    "base05"
    "base06"
    "base07"
    "base08"
    "base09"
    "base0A"
    "base0B"
    "base0C"
    "base0D"
    "base0E"
    "base0F"
  ];

  setupLine = name: "  ${name} = '#${cfg.colors.${name}}',";
in {
  options.govim.stylix = {
    enable = lib.mkEnableOption ''
      the Stylix base16 colorscheme override. Disables govim's built-in theme
      and applies the host palette through base16-nvim instead
    '';

    colors = lib.mkOption {
      # raw: Stylix's colour attrset is a functor, and every consumer only ever
      # reads `baseXX` off it. Anything stricter breaks on the real value.
      type = lib.types.raw;
      default = {};
      example = lib.literalExpression "config.lib.stylix.colors";
      description = ''
        A base16 palette: an attrset carrying `base00` … `base0F` as
        six-digit hex strings *without* a leading `#`. On a Stylix host this
        is `config.lib.stylix.colors` verbatim.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.all (n: cfg.colors ? ${n}) names;
        message = let
          missing = lib.filter (n: !(cfg.colors ? ${n})) names;
        in "govim.stylix.colors is missing base16 slots: ${lib.concatStringsSep ", " missing}";
      }
    ];

    # Only the enable flag is forced — `name` and `style` stay at their
    # common.nix values. Forcing the whole `vim.theme` attrset (as the
    # downstream copy of this did) means restating every sub-option, which
    # silently drops any new one added upstream.
    vim.theme.enable = lib.mkForce false;

    vim.extraPlugins.base16-nvim = {
      package = pkgs.vimPlugins.base16-nvim;
      setup = "";
    };

    # entryAfter ["basic"] puts this after nvf's own option-setting block, so
    # `termguicolors` is live before the colorscheme is applied.
    #
    # Anything that samples highlight groups at startup must re-read them on
    # the ColorScheme event, because this fires after those plugins have set
    # themselves up — see `luaConfigRC."lualine-bubbles"` in
    # variants/default.nix, which is the reference implementation.
    vim.luaConfigRC.stylixTheme = lib.nvim.dag.entryAfter ["basic"] ''
      require('base16-colorscheme').setup({
      ${lib.concatStringsSep "\n" (map setupLine names)}
      })
    '';
  };
}
