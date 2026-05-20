# govim — Neovim, built on [nvf]

A flake-based Neovim config with two **variants** for different jobs:

| Variant   | Purpose                         | Use it for                           |
|-----------|---------------------------------|--------------------------------------|
| `minimal` | Tiny, fast, no LSP              | Servers, ephemeral shells, `nix run` |
| `default` | Daily-driver IDE + org/PKM      | Local dev, notes, CalDAV sync        |

Built on top of [`NotAShelf/nvf`][nvf] using its `neovimConfiguration` library
function. Each variant is one file in `modules/variants/` layered on top of the
shared `modules/common.nix`. Language modules live in `modules/languages/`.

[nvf]: https://github.com/NotAShelf/nvf

---

## Try it without installing

```sh
# Tiny one, perfect for SSH sessions:
nix run github:lutzgo/govim#minimal -- file.txt

# Full IDE (default):
nix run github:lutzgo/govim
```

Add the nvf cache to skip building plugins from source:

```sh
cachix use nvf
```

## Use it from your system flake

```nix
inputs.govim = {
  url = "github:lutzgo/govim";
  # nvf expects nixpkgs-unstable — do not follow your stable nixpkgs
};
```

Drop the package you want into `home.packages` (or `environment.systemPackages`):

```nix
{ inputs, pkgs, ... }: {
  home.packages = [ inputs.govim.packages.${pkgs.system}.default ];
}
```

Per-host variant selection:

```nix
# laptop
home.packages = [ inputs.govim.packages.${pkgs.system}.default ];

# headless box
environment.systemPackages = [ inputs.govim.packages.${pkgs.system}.minimal ];
```

Or use the thin home-manager module wrapper (exported as `homeManagerModules.default`):

```nix
{ inputs, ... }: {
  imports = [ inputs.govim.homeManagerModules.default ];

  programs.my-nvim = {
    enable  = true;
    variant = "default";   # minimal | default
  };
}
```

## Layout

```
flake.nix
modules/
  common.nix             # shared: leader, keymaps, which-key, theme, clipboard
  home-manager.nix       # programs.my-nvim.{enable,variant} HM module
  languages/             # one file per language, imported by default
    nix.nix  lua.nix  bash.nix  markdown.nix  python.nix
    rust.nix  typescript.nix  go.nix  typst.nix  org.nix
  variants/
    minimal.nix          # server-friendly baseline
    default.nix          # daily driver (imports all languages/)
docs/                    # mdBook site — nix build .#docs
```

## Adding a language

Each language file enables treesitter + LSP + formatter. Most languages are
a one-liner in the variant file:

```nix
vim.languages.rust.enable = true;
```

For anything that needs custom setup (LSP quirks, extra plugins), extract to
`modules/languages/<lang>.nix` and import it from the variant. See
`modules/languages/typst.nix` (tinymist LSP) or `modules/languages/org.nix`
(custom tree-sitter grammar) for examples.

Browse the full option set in the [nvf options manual][opts].

[opts]: https://nvf.notashelf.dev/options.html

## Org / PKM

The `default` variant includes a full org-mode stack:

- **nvim-orgmode** — agenda, capture, scheduling, habit tracking
- **org-roam** — daily notes, backlinks, node graph
- **telescope-orgmode** — fuzzy search over headings and files
- **org-bullets, org-super-agenda, org-modern** — visual polish

**Exports** (`<leader>oe*`) via pandoc + typst — HTML, DOCX, Markdown, Typst
source, PDF (pandoc → typst compile, no LaTeX required).

**CalDAV sync** — org TODOs and habits are exported as VTODO iCalendar entries
and pushed to a CalDAV server (Nextcloud) via vdirsyncer. See
[CalDAV Sync](docs/src/guides/caldav-sync.md) for setup.

## Notes for this setup

- **Wayland clipboard** is wired in `common.nix` via `wl-copy` — works under niri.
- **Impermanence** — the config is reproducible; don't persist `~/.config/nvim`.
  Do persist runtime state:

  ```nix
  home.persistence."/persist/home/<user>".directories = [
    ".local/share/nvim"         # undo history, shada, sessions
    ".local/state/nvim"         # swap files, logs
    ".local/share/vdirsyncer"   # vdir collections + CalDAV sync status
  ];
  ```

- **Stylix** — when the host applies a stylix palette, the colorscheme and
  lualine theme update automatically at startup via `ColorScheme` autocmd.

- **clan** — nothing clan-specific in this repo. Reference it as a flake input
  from any clan machine's home-manager config and pick a variant.

## Developing

```sh
nix develop       # alejandra, nil, statix, deadnix, mdbook
nix flake check   # builds all variants — catches regressions
nix fmt           # format all Nix files with alejandra
mdbook serve docs # live-preview the documentation
```

## License

MIT — same as nvf upstream.
