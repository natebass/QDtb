<div align="center">
  <img src="https://github.com/natebass/qdtb-doc/blob/master/documentation/static/img/logo.jpeg">
</div>

<hr>

<h4 align="center">
  <a href="https://natebass.github.io/qdtb-doc/docs">Install</a>
  ·
  <a href="https://natebass.github.io/qdtb-doc/docs">Configure</a>
  ·
  <a href="https://natebass.github.io/qdtb-doc">Docs</a>
</h4>

<div align="center"><p>
    <a href="https://github.com/natebass/qdtb/pulse">
      <img alt="Last commit" src="https://img.shields.io/github/last-commit/natebass/qdtb?style=for-the-badge&logo=starship&color=8bd5ca&logoColor=D9E0EE&labelColor=302D41"/>
    </a>
    <a href="https://github.com/natebass/qdtb/blob/master/LICENSE">
      <img alt="License" src="https://img.shields.io/github/license/natebass/qdtb?style=for-the-badge&logo=starship&color=ee999f&logoColor=D9E0EE&labelColor=302D41" />
    </a>
    <a href="https://github.com/natebass/qdtb/stargazers">
      <img alt="Stars" src="https://img.shields.io/github/stars/natebass/qdtb?style=for-the-badge&logo=starship&color=c69ff5&logoColor=D9E0EE&labelColor=302D41" />
    </a>
    <a href="https://natebass.github.io/qdtb-doc/blog">
      <img src="https://img.shields.io/badge/blog-latest_posts-orange?style=for-the-badge&logo=rss&logoColor=white" alt="Blog" />
    </a>
</p></div>

# QDtb Neovim configuration

Welcome to my personal Neovim configuration. It is partly based on [💤 lazy.nvim](https://github.com/folke/lazy.nvim) and uses many [mini.nvim](https://github.com/nvim-mini/mini.nvim) plugins.

![image](https://raw.githubusercontent.com/natebass/qdtb-doc/refs/heads/master/screenshots/screenshot_01.png)
![image](https://raw.githubusercontent.com/natebass/qdtb-doc/refs/heads/master/screenshots/screenshot_02.png)

## ✨ Features

- 💻 Continue where you left off. Save and resume sessions with **Session Manager**. It uses mhinz/startify and mhinz/session.

## Requirements

- Neovim >= **0.12**
- A [Nerd Font](https://www.nerdfonts.com/) **_(recommended)_**

> [!WARNING]
> Install with caution. This effects your Neovim configuration.

## Install

Clone into `stdpath("config")`.

## 📂 File structure

Here is a breakdown of the Lua folder.

<pre>
~/.config/nvim
├── 📂 <b>colors</b>/
│   ├── miniautumn.lua
├── 📂 <b>lua</b>/
│   ├── 📂 <b>config</b>/          # Core configuration
│   │   ├── autocmds.lua    # Automatic command definitions
│   │   ├── keymaps.lua     # Global keybindings
│   │   ├── mini.lua        # mini.nvim initialization
│   │   └── options.lua     # Vim options and variables
│   └── 📂 <b>plugins</b>/         # My custom plugins
│       ├── 📂 <b>code_style</b>/
│       ├── 📂 <b>qdtb</b>/        # General utility scripts
├── init.lua
└── nvim-pack-lock.json     # Plugin lockfile, using the native NVIM package manager.
</pre>

## Local data directory

This project uses the native NVIM package manager. Here is the reccommeded folder sturcture
**that must be created manually**.

> [!NOTE]
> Neovide Flatpak resolves `stdpath("data")` to its sandbox data directory.
> On this machine that is `./data/nvim/`, but another installation or Flatpak
> application ID will use a different path. Do not commit this directory.

<pre>
{stdpath("data")}
├── mini-visits-index        # mini.visits persistent index
├── session/                 # mini.sessions and session-manager state
├── telescope_history        # Telescope picker history
└── site/
    ├── pack/
    │   └── core/
    │       ├── start/
    │       │   └── mini.nvim/       # Always available at startup
    │       └── opt/
    │           ├── telescope.nvim/  # Native vim.pack-managed package
    │           ├── nerdtree/
    │           ├── copilot.vim/
    │           └── ...              # Other optional native packages
    ├── parser/              # Installed Tree-sitter parser binaries
    ├── parser-info/         # Tree-sitter parser metadata
    └── queries/             # Locally installed Tree-sitter queries
</pre>

### Plugin management and loading

`plugin/packages.lua` is the authoritative list of non-mini plugins. It uses
Neovim's built-in `vim.pack` API rather than a third-party package manager:

- `vim.pack.add(..., { load = false })` installs missing packages and uses
  `nvim-pack-lock.json` without sourcing every optional plugin during
  startup.
- Packages are stored under `site/pack/core/opt/` and loaded only when needed
  with Neovim's built-in `:packadd` command.
- Command-oriented plugins are loaded when their command is first used
  (`:NERDTree`, `:Goyo`, `:Limelight`, `:Startify`, and `:TZNarrow`).
- Copilot loads on first Insert mode entry and WakaTime after `VimEnter`.
- `mini.nvim` remains a `start` package because core configuration requires
  several `mini.*` modules during startup. Secondary mini modules initialize
  after `VimEnter`.

On a new computer, clone this configuration, install `mini.nvim` in
`{stdpath("data")}/site/pack/core/start/mini.nvim`, then start Neovim. The
native package declaration installs the remaining missing packages into the
local `opt/` directory. Use `:lua vim.pack.update()` to refresh them, and keep
the resulting `nvim-pack-lock.json` in Git to reproduce revisions.

## Resources

- The QDtb documentation repository https://github.com/natebass/qdtb-doc.
