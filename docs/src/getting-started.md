# Getting Started

## Try without installing

```sh
# Minimal — ideal for SSH sessions
nix run github:lutzgo/govim#minimal -- file.txt

# Default IDE
nix run github:lutzgo/govim
```

Add the nvf cache first to avoid building plugins from source:

```sh
cachix use nvf
```

## Use from your system flake

```nix
# flake.nix
inputs.my-nvim = {
  url = "github:<you>/<repo>";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Drop the package you want into `home.packages`:

```nix
home.packages = [ inputs.my-nvim.packages.${pkgs.system}.default ];
```

Or use the home-manager module for a cleaner interface:

```nix
{ inputs, ... }: {
  imports = [ inputs.my-nvim.homeManagerModules.default ];

  programs.my-nvim = {
    enable = true;
    variant = "default";  # minimal | default
  };
}
```

## Impermanence

The config itself is reproducible — don't persist `~/.config/nvim`.
Do persist state so undo history, sessions, and `:shada` survive reboots:

```nix
home.persistence."/persist/home/<user>" = {
  directories = [
    ".local/share/nvim"   # undo history, shada, sessions
    ".local/state/nvim"   # swap files, logs
  ];
};
```

For org and CalDAV sync, also persist:

```nix
"citizengo/note"                # Nextcloud-synced org content
".local/share/org-roam.nvim"   # roam DB (rebuild with :OrgRoamSyncDatabase if lost)
".local/share/vdirsyncer"       # vdir collections + CalDAV sync status
```

## Developing

```sh
nix develop       # enters shell with alejandra, nil, statix, deadnix, mdbook
nix flake check   # builds every variant — catches regressions
nix fmt           # formats all Nix files with alejandra
mdbook serve docs # live-preview this documentation
```
