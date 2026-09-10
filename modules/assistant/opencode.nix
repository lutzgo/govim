# opencode.nvim — drive the opencode CLI agent from inside Neovim.
#
# ── WHY THERE IS NO MODEL OR PROVIDER CONFIG IN THIS FILE ────────────────
#
# opencode.nvim does not talk to a model. It talks to an `opencode` *server*
# over HTTP, and that server reads `~/.config/opencode/config.json` for its
# provider, base URL and model. On every machine that matters, clanarchy
# already writes that file — `service-modules/local-ai.nix`, `roles.opencode`:
#
#   jens     provider `local`  → http://127.0.0.1:11435/v1 (SSH forward to
#                                ernst's llama-swap)  model local/qwen3-coder-30b
#   miralda  provider `ollama` → http://127.0.0.1:11434/v1 (its own ollama)
#                                model ollama/qwen2.5-coder:7b
#
# So the endpoint is a per-host fact and it is already declared, once, in the
# place that also owns the tunnel unit and the model weights. Restating a model
# name here would fork that decision: govim is one flake consumed by several
# machines, and a hardcoded `local/qwen3-coder-30b` would be wrong on miralda
# the moment it were written. Inheriting the CLI's config is what makes this
# module correct on both without knowing which one it is running on.
#
# To change which model the editor uses, edit clanarchy's
# `roles.opencode.machines.<host>.settings.model` — not this file.
{
  pkgs,
  lib,
  ...
}: {
  vim = {
    # The opencode CLI itself, on nvim's PATH.
    #
    # BUNDLED HERE DELIBERATELY, even though clanarchy also puts opencode in
    # `environment.systemPackages`. opencode.nvim speaks opencode's server API,
    # which is versioned with the CLI, so the plugin and the binary have to come
    # from one nixpkgs or a system-level opencode bump can silently desync the
    # pair. nvf's wrapper puts extraPackages ahead of the system PATH, so this
    # is the one nvim resolves; the systemPackages copy stays for shell use.
    extraPackages = [pkgs.opencode];

    # Required by opencode.nvim's `events.reload`: opencode edits files on disk
    # behind nvim's back, and without autoread the buffer keeps showing stale
    # text until it is manually reloaded.
    options.autoread = true;

    # opencode.nvim is configured through a global rather than a setup() call
    # (see the header of its lua/opencode/config.lua), which maps straight onto
    # vim.globals — there is no setup Lua to write.
    #
    # Only plain data is set here. The defaults for `server.start/stop/toggle`
    # are Lua *functions* that open the agent in a 35%-wide right split; they
    # cannot be expressed in Nix and are deliberately left untouched.
    globals.opencode_opts = {
      # Extra prompts on top of the built-in set (explain/fix/review/test/…).
      # tbl_deep_extend merges, so the shipped prompts all survive.
      select.prompts = {
        # This is a Nix flake first. A review that does not know that suggests
        # imperative fixes for declarative problems.
        nix = "Review @this as Nix. Flag impurities, unpinned inputs, and anything that would fail `nix flake check`.";
        commit = "Write a conventional-commit message (feat/fix/chore/docs, optional scope) for @diff. Imperative subject, <=70 chars.";
      };
    };

    extraPlugins.opencode-nvim = {
      package = pkgs.vimPlugins.opencode-nvim;
      # `ask()` uses snacks.input and `select()` uses vim.ui.select; both are
      # already live by the time a keymap can fire, and the plugin reads
      # vim.g.opencode_opts lazily on first require. Nothing to run at startup.
      setup = "";
      # snacks.input being *enabled* is what makes ask() render as a float
      # instead of the bare cmdline prompt — opencode.nvim checks
      # snacks.config.get("input").enabled and silently downgrades if it is off.
      after = ["snacks-nvim"];
    };

    # ── Keymaps (<leader>a*) ──────────────────────────────────────────────
    #
    # NOT the upstream README's <C-a>/<C-x>, which take over increment and
    # decrement — bindings this config has no business stealing. <leader>a is
    # free in the namespace table in docs/src/reference/keybindings.md.
    #
    # The n+x pairs matter: `@this` resolves to the visual selection in x mode
    # and to the cursor position in n mode, so one binding covers both.
    keymaps = let
      # Visual mode included: @this picks up the selection.
      ka = key: action: desc: {
        inherit key action desc;
        lua = true;
        mode = ["n" "x"];
        silent = true;
      };
      kn = key: action: desc: {
        inherit key action desc;
        lua = true;
        mode = ["n"];
        silent = true;
      };
      # Session commands go through command(), not prompt().
      cmd = key: c: desc: kn key "function() require('opencode').command('${c}') end" desc;
      # Library prompts, submitted straight through rather than via the picker.
      prompt = key: p: desc: ka key "function() require('opencode').prompt('${p}') end" desc;
    in [
      # Ask, with the cursor position or selection attached.
      (ka "<leader>aa" "function() require('opencode').ask('@this: ', { submit = true }) end" "Ask opencode about this")
      # Empty ask: no context, for a plain question.
      (ka "<leader>aA" "function() require('opencode').ask() end" "Ask opencode (no context)")
      # The prompt/command palette — the discoverable entry point.
      (kn "<leader>ap" "function() require('opencode').select() end" "opencode: prompt palette")
      (kn "<leader>at" "function() require('opencode').toggle() end" "opencode: toggle terminal")

      # Library prompts worth a direct binding.
      (prompt "<leader>ae" "Explain @this and its context" "Explain this")
      (prompt "<leader>ar" "Review @this for correctness and readability" "Review this")
      (prompt "<leader>af" "Fix @diagnostics" "Fix diagnostics")
      (prompt "<leader>ad" "Review the following git diff for correctness and readability: @diff" "Review git diff")
      (prompt "<leader>aT" "Add tests for @this" "Add tests for this")
      (prompt "<leader>ab" "Explain @buffer" "Explain buffer")

      # Session control.
      (cmd "<leader>an" "session.new" "Session: new")
      (cmd "<leader>as" "session.select" "Session: select")
      (cmd "<leader>ac" "session.compact" "Session: compact (shrink context)")
      (cmd "<leader>ai" "session.interrupt" "Session: interrupt")
      (cmd "<leader>au" "session.undo" "Session: undo last edit")
      (cmd "<leader>aR" "session.redo" "Session: redo")
    ];

    # which-key labels for the group and its sub-behaviour. Registered the same
    # way as the org groups in variants/default.nix, and guarded with pcall for
    # the same reason: which-key is a common.nix plugin, not a hard dependency
    # of this file.
    luaConfigRC."opencode-whichkey" = lib.nvim.dag.entryAnywhere ''
      local ok, wk = pcall(require, 'which-key')
      if ok then
        wk.add({
          { "<leader>a", group = "AI / opencode" },
        })
      end
    '';
  };
}
