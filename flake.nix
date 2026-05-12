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
    forEachSystem = f: nixpkgs.lib.genAttrs (import systems) (system: f system);

    # ------------------------------------------------------------------
    # Variants
    #
    # Each variant is a list of extra modules layered on top of the
    # shared `modules/common.nix` base. Adding a variant = drop a file
    # in `modules/variants/` and add it here.
    #
    #   minimal   – server-friendly, runnable purely via `nix run`.
    #   markdown  – writing / notes; renderers, spelling, zen.
    #   default   – daily driver IDE config (the `nix run .#` package).
    #   maximal   – kitchen sink, all languages and goodies.
    # ------------------------------------------------------------------
    variants = {
      minimal = [./modules/variants/minimal.nix];
      markdown = [./modules/variants/markdown.nix];
      default = [./modules/variants/default.nix];
      maximal = [./modules/variants/maximal.nix];
      org = [./modules/variants/org.nix];
    };

    mkNeovim = system: extraModules:
      (nvf.lib.neovimConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        modules = [./modules/common.nix] ++ extraModules;
      })
      .neovim;
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
    # ------------------------------------------------------------------
    checks = forEachSystem (
      system:
        builtins.mapAttrs (_n: pkg: pkg) self.packages.${system}
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
  };
}
