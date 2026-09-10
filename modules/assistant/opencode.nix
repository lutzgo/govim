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
#
# ── VERSION CONTRACT ─────────────────────────────────────────────────────
#
# Written against opencode.nvim 0.14.0. Its API is small and it breaks often;
# re-check these on every nixpkgs bump, because none of them fail at eval:
#
#   * The public API is exactly `ask(default)`, `select(opts)`, `prompt(str)`,
#     `command(str)`, `operator(str)`, `statusline`, `format`. There is NO
#     `toggle()`/`start()`/`stop()` — 0.13.3 removed the last of them, so a
#     keymap calling one is a nil-call at press time, not a build failure.
#   * `@diff` was REMOVED as a built-in context in 0.13.0 and is re-added
#     below, deliberately.
#   * `opts.events.reload` became a table in 0.14.0 (`reload.enabled`).
{
  pkgs,
  lib,
  ...
}: {
  vim = {
    # The opencode CLI itself, on nvim's PATH.
    #
    # BUNDLED DELIBERATELY even though clanarchy also puts opencode in
    # `environment.systemPackages`: opencode.nvim speaks the opencode server's
    # HTTP API, which is versioned with the CLI, so the plugin and the binary
    # want to come from one nixpkgs. Note this does NOT currently win over the
    # system copy — nvf appends extraPackages to PATH rather than prepending,
    # so on a clanarchy host `exepath('opencode')` still resolves to
    # /run/current-system/sw/bin/opencode. It matters only as the fallback that
    # keeps `nix run .#default` working on a host with no opencode installed.
    extraPackages = [pkgs.opencode];

    # `vim.o.autoread` is NOT set here on purpose: 0.14.0 sets it itself when
    # `events.reload.enabled` and the user has not set it (it checks
    # nvim_get_option_info2().was_set). Setting it here would only pre-empt
    # that with the identical value while looking like a second opinion.

    # opencode.nvim is configured through a global rather than a setup() call
    # (see the header of its lua/opencode/config.lua), which maps straight onto
    # vim.globals — there is no setup Lua to write.
    #
    # Only plain data goes here. `server.start` and the `contexts` entries are
    # Lua *functions*, which Nix cannot express; the ones this config changes
    # are set in luaConfigRC below instead.
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
      # No setup() call exists; config is the global above. The plugin's own
      # plugin/ files (highlight links, event handlers) are sourced by the
      # runtime, so there is nothing to run here.
      setup = "";
      # snacks.input being *enabled* is what makes ask() render as a float
      # instead of the bare cmdline prompt — opencode.nvim checks
      # snacks.config.get("input").enabled and silently downgrades if it is off.
      after = ["snacks-nvim"];
    };

    # ── @diff, restored ───────────────────────────────────────────────────
    #
    # 0.13.0 dropped the built-in `@diff` context. It is the single most useful
    # one here — "review what I am about to commit" is the main reason to ask a
    # local model anything — so it is re-registered, with the same
    # implementation the plugin used to ship (`git --no-pager diff`, nil when
    # not a repo or the diff is empty, so the placeholder drops out cleanly).
    #
    # Set on `config.opts` rather than via vim.globals because a context is a
    # function. Safe to do at startup: the plugin's own plugin/ files already
    # load it, so this require costs nothing extra.
    luaConfigRC."opencode-diff-context" = lib.nvim.dag.entryAnywhere ''
      local ok, oc_config = pcall(require, 'opencode.config')
      if ok then
        oc_config.opts.contexts['@diff'] = function()
          local result = vim.system({ 'git', '--no-pager', 'diff' }, { text = true }):wait()
          -- 129 is git's "not a repository"; anything else non-zero is a real
          -- failure worth surfacing rather than silently sending an empty diff.
          if result.code == 129 then return nil end
          if result.code ~= 0 then
            vim.notify('opencode @diff: git diff failed', vim.log.levels.WARN)
            return nil
          end
          if result.stdout == "" then return nil end
          return result.stdout
        end
      end
    '';

    # ── Showing the agent's terminal ──────────────────────────────────────
    #
    # There is no toggle() in the API any more, and the server is started for
    # you on first use (`server.connect`/`server.start`), which opens
    # `vsplit term://opencode --port`. What is missing is a way back to that
    # window once you have moved off it, so this focuses the existing opencode
    # terminal if there is one and only starts a server when there is not —
    # blindly re-running server.start would leave a second agent running.
    luaConfigRC."opencode-terminal" = lib.nvim.dag.entryAnywhere ''
      function _G.opencode_focus()
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          local name = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win))
          if name:match('^term://.*opencode') then
            vim.api.nvim_set_current_win(win)
            return
          end
        end
        local ok, oc_config = pcall(require, 'opencode.config')
        if ok and type(oc_config.opts.server.start) == 'function' then
          oc_config.opts.server.start()
        end
      end
    '';

    # ── Keymaps (<leader>a*) ──────────────────────────────────────────────
    #
    # NOT the upstream README's <C-a>/<C-x>, which take over increment and
    # decrement — bindings this config has no business stealing. <leader>a was
    # free in CLAUDE.md's namespace table and is now claimed there.
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
      # Session control goes through command(), which names an opencode TUI
      # command rather than sending a prompt.
      cmd = key: c: desc: kn key "function() require('opencode').command('${c}') end" desc;
      # Library prompts, sent directly rather than picked out of the palette.
      prompt = key: p: desc: ka key "function() require('opencode').prompt('${p}') end" desc;
    in [
      # ask() takes only a default string in 0.14.0 — it prefills the input and
      # you hit <CR> to send. There is no submit option to pass.
      (ka "<leader>aa" "function() require('opencode').ask('@this: ') end" "Ask opencode about this")
      (ka "<leader>aA" "function() require('opencode').ask() end" "Ask opencode (no context)")
      # The palette: prompt library + session commands + server connect/start.
      (kn "<leader>ap" "function() require('opencode').select() end" "opencode: palette")
      (kn "<leader>at" "function() _G.opencode_focus() end" "opencode: focus/open terminal")

      # Library prompts worth a direct binding.
      (prompt "<leader>ae" "Explain @this and its context" "Explain this")
      (prompt "<leader>ar" "Review @this for correctness and readability" "Review this")
      (prompt "<leader>af" "Fix @diagnostics" "Fix diagnostics")
      (prompt "<leader>ad" "Review the following git diff for correctness and readability: @diff" "Review git diff")
      (prompt "<leader>aT" "Add tests for @this" "Add tests for this")
      (prompt "<leader>ab" "Explain @buffer" "Explain buffer")

      # Session control.
      (cmd "<leader>an" "session.new" "Session: new")
      (cmd "<leader>aS" "session.select" "Session: select")
      (cmd "<leader>ac" "session.compact" "Session: compact (shrink context)")
      (cmd "<leader>ai" "session.interrupt" "Session: interrupt")
      (cmd "<leader>au" "session.undo" "Session: undo last edit")
      (cmd "<leader>aR" "session.redo" "Session: redo")
    ];

    # which-key labels for the group. Registered the same way as the org groups
    # in variants/default.nix, and guarded with pcall for the same reason:
    # which-key is a common.nix plugin, not a hard dependency of this file.
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
