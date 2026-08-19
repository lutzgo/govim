# clanarchy Integration

govim is consumed by [clanarchy](https://github.com/lutzgo/clanarchy), the NixOS
clan that runs the author's machines. Nothing in this repo is clan-specific —
but the two are wired together in a way worth writing down, because the wiring
lives in two repos and breaks silently when only one of them moves.

## How the host pulls govim in

clanarchy does **not** install a govim package. It drives nvf itself and imports
govim's modules into its own nvf evaluation:

```nix
# clanarchy: modules/users/lgo.nix
programs.nvf = {
  enable = true;
  settings = {
    imports = with inputs.govim.nvfModules; [common default stylix];

    govim.stylix = {
      enable = true;
      colors = config.lib.stylix.colors;
    };
  };
};
```

Two supporting bits on the clanarchy side:

- `home-manager.sharedModules = [inputs.govim.homeManagerModules.nvf]` — the nvf
  option namespace has to be declared at the NixOS level. A per-user import
  cannot bootstrap its own option types.
- `nvf.follows = "govim/nvf"` in `flake.nix` — one nvf, so `inputs.nvf.lib`
  helpers and govim's modules agree on the module system they are evaluated in.

### Why modules and not a package

A package is sealed. Once `nix build .#default` has run, the colorscheme is
baked in and the host cannot reach it. Importing the modules puts govim's
options inside the host's own nvf evaluation, where host settings — the Stylix
palette, most importantly — merge with them normally.

The `programs.my-nvim` home-manager wrapper is the other path, for hosts that
just want the binary and have no palette to apply:

```nix
imports = [inputs.govim.homeManagerModules.default];
programs.my-nvim = {
  enable = true;
  variant = "default"; # minimal | default
};
```

## Theming: `govim.stylix`

`modules/common.nix` hardcodes catppuccin-mocha so that
`nix run github:lutzgo/govim` looks right on a machine that has never heard of
Stylix. A Stylix host already owns a palette and needs to replace it.

`modules/stylix.nix` does that replacement, and it lives here rather than
downstream so it moves in lockstep with the theme it overrides:

| Option | Meaning |
|--------|---------|
| `govim.stylix.enable` | Turn off govim's built-in theme, apply the host palette via base16-nvim |
| `govim.stylix.colors` | A base16 attrset — `base00` … `base0F` as hex **without** a leading `#`. On a Stylix host, `config.lib.stylix.colors` verbatim |

It force-disables `vim.theme.enable` only, leaving `name` and `style` alone —
forcing the whole `vim.theme` attrset means restating every sub-option and
silently dropping any that nvf adds later.

`nix flake check` builds `checks.stylix`: the `default` variant with this module
applied to a dummy palette. The downstream theming contract is therefore tested
here, not discovered broken during a deploy.

### Anything reading colors must re-read on `ColorScheme`

The palette is applied *after* startup. A plugin that samples a highlight group
while setting itself up gets the pre-Stylix value and keeps it. The fix is to
re-run setup on the event:

```lua
_lualine_setup()
vim.api.nvim_create_autocmd("ColorScheme", { callback = _lualine_setup })
```

That is `luaConfigRC."lualine-bubbles"` in `modules/variants/default.nix` — the
reference implementation for anything else with the same problem.

## Keybind layers

Four programs stack in one terminal on a clanarchy desktop, each on its own
modifier:

| Layer | Modifier | Unlock |
|-------|----------|--------|
| niri (compositor) | `Mod` (Super) | Always |
| Zellij (multiplexer) | `Alt` | Autolock; `Alt+G` toggles |
| **govim** | `Ctrl` / `Space` / `,` | Normal mode |
| nushell | Emacs keys | Outside the editor |

govim binds no `Alt` or `Super` chord, so there is nothing to collide. Zellij's
autolock trigger list is `hx|nvim|vim|git|fzf|zoxide|yazi` — `nvim` is on it, so
Zellij drops to locked mode when govim starts and passes even `Alt` straight
through.

Because `clanarchy.users.lgo.editor` switches between govim and helix on the
same machine, a few bindings are deliberately aligned across the two — see
[Keybindings](../reference/keybindings.md#where-govim-sits-in-the-hosts-keybind-layers).

## Impermanence

`~/.config/nvim` is generated and disposable — do not persist it. Runtime state
must survive the rollback:

```nix
home.persistence."/persist/home/lgo".directories = [
  ".local/share/nvim"       # undo history, shada, sessions, org-roam db
  ".local/state/nvim"       # swap files, logs
  ".local/share/vdirsyncer" # vdir collections + CalDAV sync status
];
```

Also persist `~/citizengo/notes` — every org path in
`modules/variants/default.nix` points there, and it is real user data, not
state.

## What breaks the integration

Changes here that require a coordinated clanarchy PR:

- Renaming or removing anything in `nvfModules` (`common`, `minimal`,
  `default`, `stylix`). The older interpolated form,
  `"${inputs.govim}/modules/variants/default.nix"`, hardcodes the file layout —
  the named attributes exist so the layout can move without breaking the host.
- Making any plugin setup depend on `vim.theme.enable` being true. It is forced
  off on every Stylix host.
- Changing the `govim.stylix.colors` shape.
- Moving the org file paths out of `~/citizengo/notes/`, which clanarchy backs
  up and syncs.
