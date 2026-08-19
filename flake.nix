{
  description = "Personal multi-variant Neovim configuration built on nvf";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Make nvf follow our nixpkgs to keep evaluation cheap and consistent
    # with the rest of the user's flake graph (clan / home-manager / etc.).
    nvf = {
      url = "github:notashelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Lets the consumer override which systems we build for.
    systems.url = "github:nix-systems/default-linux";
  };

  outputs = {
    self,
    nixpkgs,
    nvf,
    systems,
  }: let
    forEachSystem = f: nixpkgs.lib.genAttrs (import systems) f;

    # ------------------------------------------------------------------
    # Variants
    #
    # Each variant is a list of extra modules layered on top of the
    # shared `modules/common.nix` base.
    #
    #   minimal  – server-friendly, runnable purely via `nix run`.
    #   default  – daily driver: IDE, org/PKM, markdown, all languages.
    # ------------------------------------------------------------------
    variants = {
      minimal = [./modules/variants/minimal.nix];
      default = [./modules/variants/default.nix];
    };

    mkNeovim = system: extraModules:
      (nvf.lib.neovimConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        modules = [./modules/common.nix] ++ extraModules;
      })
      .neovim;

    # A base16 palette used only by `checks.stylix`, so the downstream Stylix
    # override is built on every `nix flake check` instead of being discovered
    # broken on a clan machine. Values are Selenized Black — arbitrary; only
    # the shape matters.
    dummyPalette = {
      base00 = "181818";
      base01 = "252525";
      base02 = "3b3b3b";
      base03 = "777777";
      base04 = "b9b9b9";
      base05 = "dedede";
      base06 = "e3e3e3";
      base07 = "f7f7f7";
      base08 = "ed4a46";
      base09 = "e67f43";
      base0A = "dbb32d";
      base0B = "70b433";
      base0C = "3fc5b7";
      base0D = "368aeb";
      base0E = "a580e2";
      base0F = "eb6eb7";
    };
  in {
    # ------------------------------------------------------------------
    # Packages
    #
    # Build any variant directly:
    #   nix build .#minimal
    #   nix run .#markdown -- notes.md
    #
    # Or from a remote ref (handy for servers without an install):
    #   nix run github:<you>/<repo>#minimal
    # ------------------------------------------------------------------
    packages = forEachSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in
        builtins.mapAttrs (_name: mods: mkNeovim system mods) variants
        // {
          default = mkNeovim system variants.default;

          # Build the mdBook documentation site.
          # nix build .#docs  →  result/index.html
          docs = pkgs.stdenv.mkDerivation {
            name = "govim-docs";
            src = ./docs;
            nativeBuildInputs = [pkgs.mdbook];
            buildPhase = "mdbook build";
            installPhase = "cp -r book $out";
          };
        }
    );

    # ------------------------------------------------------------------
    # Apps – so `nix run` picks the wrapped binary cleanly.
    # Only the nvim variants are runnable; docs has no binary.
    # ------------------------------------------------------------------
    apps = forEachSystem (system: let
      mkApp = mods: {
        type = "app";
        program = "${mkNeovim system mods}/bin/nvim";
      };
    in
      builtins.mapAttrs (_n: mkApp) variants);

    # ------------------------------------------------------------------
    # Checks – building every variant *is* the check.
    # `nix flake check` catches regressions across the matrix.
    #
    # `stylix` additionally builds the `default` variant with the Stylix
    # override applied, which is how clanarchy consumes this repo. Without it,
    # a change to the theme wiring only fails downstream, on a machine, during
    # a deploy.
    # ------------------------------------------------------------------
    checks = forEachSystem (
      system:
        builtins.mapAttrs (_n: pkg: pkg) self.packages.${system}
        // {
          stylix = mkNeovim system (variants.default
            ++ [
              ./modules/stylix.nix
              {
                govim.stylix = {
                  enable = true;
                  colors = dummyPalette;
                };
              }
            ]);
        }
    );

    # ------------------------------------------------------------------
    # Formatter – `nix fmt`
    # ------------------------------------------------------------------
    formatter = forEachSystem (system: nixpkgs.legacyPackages.${system}.alejandra);

    # ------------------------------------------------------------------
    # Dev shell – tools you want when hacking on the config itself.
    # ------------------------------------------------------------------
    devShells = forEachSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = pkgs.mkShellNoCC {
        packages = with pkgs; [
          alejandra
          nil
          statix
          deadnix
          mdbook # docs: `mdbook serve docs` for live preview
        ];
      };
    });

    # ------------------------------------------------------------------
    # Module re-exports
    #
    # homeManagerModules.default – thin wrapper; lets a downstream host
    # pick a variant by name via `programs.my-nvim.variant`.
    #
    # homeManagerModules.nvf / nixosModules.nvf – raw nvf modules for
    # advanced users who want to drive nvf options directly.
    # ------------------------------------------------------------------
    homeManagerModules = {
      default = import ./modules/home-manager.nix {inherit self;};
      nvf = nvf.homeManagerModules.default;
    };
    nixosModules.nvf = nvf.nixosModules.default;

    # ------------------------------------------------------------------
    # nvf module paths
    #
    # For hosts that drive nvf themselves (via `programs.nvf.settings`)
    # instead of installing one of our packages — they need govim's option
    # set inside *their* nvf evaluation so host theming and host options can
    # merge with it. A package cannot be re-themed after the fact; a module
    # can.
    #
    #   programs.nvf.settings = {
    #     imports = with inputs.govim.nvfModules; [common default stylix];
    #     govim.stylix = {
    #       enable = true;
    #       colors = config.lib.stylix.colors;
    #     };
    #   };
    #
    # These are the supported entry points. Consumers previously reached in
    # with "''${inputs.govim}/modules/variants/default.nix", which works but
    # hardcodes the layout — any refactor here silently breaks their eval.
    # Naming them makes the surface explicit and keeps the freedom to move
    # files behind it.
    #
    # `common` is required: every variant layers on it.
    # ------------------------------------------------------------------
    nvfModules = {
      common = ./modules/common.nix;
      minimal = ./modules/variants/minimal.nix;
      default = ./modules/variants/default.nix;
      stylix = ./modules/stylix.nix;
    };
  };
}
