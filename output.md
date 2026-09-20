# `.luarc.json`, lazydev, and on-demand package loading

Notes from working through how Lua type-checking and plugin loading fit together in
this config.

## What `.luarc.json` actually is

It configures **lua-language-server** (`lua_ls`), not Neovim. lua_ls is a separate
process that never executes the config — it only reads files. When it starts and
finds `.luarc.json` at the workspace root, it merges those settings over whatever
the client sent.

Keys used here:

| Key | Effect |
| --- | --- |
| `runtime.version: "LuaJIT"` | Lua 5.1 / LuaJIT semantics (`jit`, `bit`), which is what Neovim embeds. |
| `workspace.checkThirdParty: false` | Suppresses the "configure library X?" prompt. |
| `diagnostics.globals` | Names exempted from `undefined-global`. |

### The non-obvious interaction

Neovim's built-in `lua_ls` config (and nvim-lspconfig before it) has an `on_init`
that auto-injects `runtime.version = "LuaJIT"` **and** the whole `$VIMRUNTIME`
library — but only when no `.luarc.json` / `.luarc.jsonc` exists. Creating the file
switches that auto-setup off and makes it your job. That is why `runtime.version`
has to stay in the file: it is not redundant, it is replacing something the file
itself disabled.

`.luarc.json` is also a root marker for `lua_ls`, so it pins the workspace root.
Here that resolves to the config directory, which is correct.

## What was trimmed and why

Two separate removals, for two different reasons.

**`workspace.library: ["${3rd}/luv/library"]`** — duplicate work. lazydev
(`after/plugin/lsp.lua`) already loads `luvit-meta/library` on the word `vim%.uv`,
and it updates itself as plugins change. `lua/plugins/code_style/lua.lua` already
carried a comment saying library/globals should not be hand-defined there.

**`"Snacks"` from `diagnostics.globals`** — strictly worse than what replaces it. A
`diagnostics.globals` entry only silences the `undefined-global` warning; the name
resolves to `any` with no completion. lazydev's
`{ path = "snacks.nvim", words = { "Snacks" } }` pulls snacks.nvim into the library
as soon as the word appears in the buffer, and `lua/snacks/init.lua:12` does
`_G.Snacks = M`, which lua_ls reads as a real global definition with the full type
attached. This is the one removal that depends on lazydev's word-trigger firing; if
`undefined-global: Snacks` ever shows up, put the entry back.

Resulting file:

```json
{
  "runtime.version": "LuaJIT",
  "workspace.checkThirdParty": false,
  "diagnostics.globals": ["vim", "MiniFiles", "MiniPick", "MiniExtra", "MiniSessions"]
}
```

The alternative — delete `.luarc.json` entirely and move `diagnostics.globals` into
the `settings.Lua` table in `lua/plugins/code_style/lua.lua` — also works and
re-enables the built-in auto-config. The JSON file was kept because it survives
outside Neovim: a bare `lua-language-server` run from other tooling still reads it.

## Globals vs. modules

This is the split that matters:

- **lazydev handles modules.** It resolves types on demand when it sees a
  `require("...")` or `---@module "..."` in the buffer.
- **lazydev does not handle globals**, unless something drags the defining file into
  the library (the snacks case above, via `words`).

So `MiniFiles` — used as a bare global at `after/plugin/mini.lua:160` — needs the
`diagnostics.globals` entry, because there is no lazydev `words` entry for mini.nvim
to bring its source in on the strength of a bare reference.

`MiniPick`, `MiniExtra` and `MiniSessions` currently appear only inside
`<cmd>lua ...` strings in `after/plugin/keymaps.lua`, which lua_ls never parses.
They were kept as cheap insurance for when they get written in real Lua. `vim` is
already known via the runtime types but is harmless to list.

## Relationship to `plugin/packages.lua`

These are separate mechanisms that meet at exactly one point.

`plugin/packages.lua` is a **runtime** concern. The `CmdUndefined` autocmd maps each
command to its package, so typing `:Goyo` triggers `packadd goyo.vim` and Neovim
retries the command. Same idea for Copilot on `InsertEnter` and wakatime on
`VimEnter`. None of this affects lua_ls, and removing `.luarc.json` would not break
any of it.

The point of contact: everything in the second `vim.pack.add({ load = false })` call
is installed under `pack/core/opt/` rather than `start/`, and opt directories are not
on `runtimepath` until `packadd` runs. A lua_ls driven by a static
`workspace.library` list would be blind to all of them — that is the world where you
hand-maintain one library path per plugin.

lazydev closes that gap. Its non-lazy.nvim code path (`lua/lazydev/pkg.lua`,
`pack_unloaded()`) globs `packpath .. "/pack/*/opt/*"` and treats every hit as a
candidate root. So opt-installed plugins are visible to the language server even
though Neovim has not loaded them. That is why the snacks entry in the lazydev
`library` table resolves despite snacks being `load = false`.

### Summary of responsibilities

- `plugin/packages.lua` — what the *editor* loads, and when.
- lazydev — what the *language server* knows about, independent of the above.
- `.luarc.json` — the static fallback for lua_ls: runtime version, prompt
  suppression, and globals lazydev cannot infer.
