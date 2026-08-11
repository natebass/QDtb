Neovim data directories and Windows migration
==============================================

Scope
-----

This repository contains the configuration only.  Installed plugins,
Tree-sitter parsers, histories, sessions, and other runtime state belong to
Neovim's data directory and must be migrated separately on each computer.

Current Linux layout
--------------------

The repository's documented Linux data directory is represented by
``stdpath("data")``.  On the referenced Flatpak setup it is ``./data/nvim/``;
other Linux installations may resolve it to a user data directory instead.
The relevant layout is::

    {stdpath("data")}/
    ├── mini-visits-index
    ├── session/
    ├── telescope_history
    └── site/
        ├── pack/
        │   └── core/
        │       ├── start/
        │       │   └── mini.nvim/
        │       └── opt/
        │           ├── telescope.nvim/
        │           ├── plenary.nvim/
        │           ├── vague.nvim/
        │           ├── leap.nvim/
        │           ├── focus.nvim/
        │           ├── nerdtree/
        │           ├── copilot.vim/
        │           └── ... other packages from packages.lua
        ├── parser/
        ├── parser-info/
        └── queries/

The exact package set can change with ``plugin/packages.lua`` and
``nvim-pack-lock.json``.  ``mini.nvim`` is intentionally under ``start``;
the other native packages are under ``opt`` and are loaded with ``:packadd``.

Likely Windows layout
---------------------

For a standard Windows Neovim installation, ``stdpath("data")`` normally
resolves to::

    %LOCALAPPDATA%\nvim-data

The corresponding package tree is therefore::

    C:\Users\<user>\AppData\Local\nvim-data\
    └── site\
        └── pack\
            └── core\
                ├── start\
                │   └── mini.nvim\
                └── opt\
                    ├── telescope.nvim\
                    ├── plenary.nvim\
                    ├── vague.nvim\
                    ├── leap.nvim\
                    ├── focus.nvim\
                    ├── nerdtree\
                    ├── copilot.vim\
                    └── ... other packages

The configuration directory is separate: standard Windows Neovim uses
``%LOCALAPPDATA%\nvim`` (the equivalent of ``stdpath("config")``).  Do not
place the repository checkout inside ``nvim-data``.

Migrating an older Windows plugin tree
--------------------------------------

An older setup may have used a package name other than ``core`` or may have
placed plugins directly under ``site/pack/<name>/start``.  The directory
name is not important to Neovim, but this configuration expects the native
package declaration and lockfile to manage the packages in the ``core``
package directory.  A safe migration is:

1. Close every Neovim/Neovide process.
2. In the old data directory, identify plugin directories below
   ``site\pack\*\start`` and ``site\pack\*\opt``.  Do not copy the old
   ``lazy``/``packer`` metadata as if it were plugin source.
3. Create
   ``%LOCALAPPDATA%\nvim-data\site\pack\core\start`` and
   ``...\core\opt``.
4. Copy ``mini.nvim`` to ``start``.  Copy the other plugin directories to
   ``opt``.  Preserve each plugin's complete directory, including its
   ``plugin``, ``lua``, ``after``, and ``ftdetect`` subdirectories.
5. Remove stale duplicate copies only after testing.  Do not overwrite a
   newer directory blindly; rename it to a backup first.
6. Copy ``nvim-pack-lock.json`` with the configuration checkout, then start
   Neovim and let ``vim.pack`` reconcile missing or locked revisions.  Use
   ``:lua vim.pack.update()`` only when intentionally updating revisions.
7. Confirm the result with ``:lua print(vim.fn.stdpath('data'))`` and
   ``:checkhealth``.  Test ``:Startify``, ``:Goyo``, Telescope, and entering
   Insert mode to verify deferred packages.

If the old Windows installation used a third-party manager, it is usually
safer to keep its old data directory as a backup and let this configuration
reinstall packages from the native declarations.  Copy only valuable
persistent state such as sessions, ``mini-visits-index``, and
``telescope_history`` when their formats are known to be compatible.

Paths can differ for a portable, Scoop, or custom Neovim installation.  The
authoritative path is always the value printed by
``:lua print(vim.fn.stdpath('data'))`` on that Windows machine.
