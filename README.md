# nvim — multi-variant Neovim, built on [nvf]

A flake-based Neovim config with several **variants** for different jobs:

| Variant    | Purpose                               | Use it for                                  |
| ---------- | ------------------------------------- | ------------------------------------------- |
| `minimal`  | Tiny, fast, no LSP                    | Servers, ephemeral shells, `nix run`        |
| `markdown` | Prose, notes, rendering, spellcheck   | Wiki / journal / docs editing               |
| `default`  | Daily-driver IDE (this is `.#`)       | Local dev on your usual stack               |
| `maximal`  | Kitchen sink: every language + DAP    | Occasional polyglot / debugging sessions    |

Built on top of [`NotAShelf/nvf`][nvf] using its `neovimConfiguration` library
function. Each variant is one file in `modules/variants/` layered on top of the
shared `modules/common.nix`.

[nvf]: https://github.com/NotAShelf/nvf

---

## Try it without installing

```sh
# Tiny one, perfect for `ssh` sessions:
nix run github:<you>/<this-repo>#minimal -- file.txt

# IDE feel:
nix run github:<you>/<this-repo>           # = .#default

# Everything:
nix run github:<you>/<this-repo>#maximal
```

Add the nvf cache to skip building plugins from source:

```sh
cachix use nvf
```

## Use it from your system flake

In your NixOS / home-manager flake:

```nix
{
  inputs = {
    # ...
    my-nvim = {
      url = "github:<you>/<this-repo>";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
```

Then drop the variant you want into `home.packages` (or `environment.systemPackages`):

```nix
{ inputs, pkgs, ... }: {
  home.packages = [ inputs.my-nvim.packages.${pkgs.system}.default ];
}
```

Per-host variant selection is just a different attribute:

```nix
# laptop
home.packages = [ inputs.my-nvim.packages.${pkgs.system}.maximal ];

# headless box
environment.systemPackages = [ inputs.my-nvim.packages.${pkgs.system}.minimal ];
```

Or use the thin home-manager module wrapper (exported as
`homeManagerModules.default`) for a slightly cleaner interface:

```nix
{ inputs, ... }: {
  imports = [ inputs.my-nvim.homeManagerModules.default ];

  programs.my-nvim = {
    enable = true;
    variant = "maximal";   # minimal | markdown | default | maximal
  };
}
```

## Layout

```
.
├── flake.nix                  # variants → packages, dev shell, formatter
├── modules/
│   ├── common.nix             # shared base: theme, options, clipboard
│   └── variants/
│       ├── minimal.nix
│       ├── markdown.nix
│       ├── default.nix
│       └── maximal.nix
└── AGENTS.md                  # prompt + context for Claude Code
```

## Adding a variant

1. Drop `modules/variants/<name>.nix`. Start with `imports = [ ./default.nix ];`
   if you want to extend the daily driver.
2. Register it in `flake.nix` under `variants`.
3. `nix build .#<name>` to verify.

## Adding a language to `default` / `maximal`

Most languages are one line in the appropriate variant:

```nix
vim.languages.rust.enable = true;
```

Browse the full list in the [nvf options manual][opts]. If a language needs
more than `enable`, prefer extracting to `modules/languages/<lang>.nix` and
importing it from the variants that use it.

[opts]: https://nvf.notashelf.dev/options.html

## Notes for this setup

- **Wayland clipboard** is wired in `common.nix` via `wl-copy` — works under
  niri.
- **Impermanence**: the config is reproducible, so you don't need to persist
  `~/.config/nvim`. Do persist `~/.local/share/nvim` and `~/.local/state/nvim`
  if you want sessions, undo history, and `:shada` to survive reboots.

  Copy-paste snippet for your impermanence config:

  ```nix
  home.persistence."/persist/home/<user>" = {
    directories = [
      ".local/share/nvim"   # undo history, plugins, sessions, shada
      ".local/state/nvim"   # swap files, log
    ];
  };
  ```
- **clan**: nothing clan-specific here. Reference this flake from any clan
  machine's home-manager config and pick a variant.

## License

MIT — same as nvf upstream.
