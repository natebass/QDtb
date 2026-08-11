Neovim startup optimization
===========================

Overview
--------

The package declaration in ``plugin/packages.lua`` uses Neovim's native
package manager with ``vim.pack.add(..., { load = false })``.  Packages can
therefore be installed, updated, and pinned in ``nvim-pack-lock.json`` without
Neovim sourcing every plugin during the initial startup path.

Only packages needed by the existing startup configuration are loaded eagerly:

* ``vague.nvim``, ``leap.nvim``, and ``focus.nvim``;
* ``lazydev.nvim`` and ``luvit-meta``; and
* Telescope and Plenary.

The remaining packages are deferred according to how they are used:

* Startify, NERDTree, Goyo, Limelight, and True Zen are loaded by the
  ``CmdUndefined`` autocmd when one of their commands is first invoked.
* Copilot is loaded on the first ``InsertEnter`` event.
* WakaTime is scheduled after ``VimEnter``, allowing the first UI frame to
  start before it is sourced.
* Secondary ``mini.nvim`` modules are initialized from a scheduled
  ``VimEnter`` callback.  This includes ``mini.ai``, ``mini.files``,
  ``mini.surround``, snippets, clue, hipatterns, and jump2d.

The result is native-only lazy loading: there is no third-party plugin
manager involved in deciding when these packages are installed or sourced.

Understanding the measurements
------------------------------

The reported headless startup measurement improved from 166.1 ms to 121.1 ms,
an approximately 45.0 ms reduction, or about 27 percent.

``headless startup`` means starting Neovim without an interactive terminal UI,
typically with a command such as ``nvim --headless`` and measuring until the
requested startup command or exit completes.  It is a repeatable way to
measure initialization work: Lua loading, option setup, package discovery,
plugin sourcing, and autocmd registration.  It does not measure the time
needed to paint a visible editor window or the user's interaction with it.

``complete startup time`` is the end-to-end time until the interactive editor
is fully usable.  It includes the headless initialization work plus terminal
or GUI creation, UI attachment, the first rendered frame, and any work
scheduled immediately after ``VimEnter``.  On this configuration, deferred
work such as secondary mini modules and WakaTime may be excluded from the
headless number when the process exits immediately, but still occurs shortly
after the UI starts in a normal session.

Consequently, the 121.1 ms result is best interpreted as a startup-path
improvement, not as a claim that every part of complete interactive startup
finishes 45 ms sooner.  The optimization moves nonessential work out of the
critical path; the exact complete-startup improvement depends on terminal or
GUI overhead, machine speed, and which deferred plugins are eventually used.

The measurements also indicate that deferred mini initialization completed
without errors, individual native package loading works, and command-triggered
loading was verified for ``:Startify`` and ``:Goyo``.  ``git diff --check``
was clean.
