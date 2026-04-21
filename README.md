<div align="center">
  <img src="https://github.com/natebass/qdtb-doc/blob/master/screenshots/qdtb_logo.jpeg">
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
    <a href="https://natebass.github.io/qdtb-doc/docs">
      <img src="https://img.shields.io/badge/docs-qdtb-blue?style=for-the-badge&logo=docusaurus&logoColor=white" alt="Docs" />
    </a>
</p></div>

# QDtb Neovim Configuration

Welcome to my personal Neovim configuration. It is partly based on [💤 lazy.nvim](https://github.com/folke/lazy.nvim) and uses mini.nvim plugins.

![image](https://raw.githubusercontent.com/natebass/qdtb-doc/refs/heads/master/screenshots/screenshot_01.png)
![image](https://raw.githubusercontent.com/natebass/qdtb-doc/refs/heads/master/screenshots/screenshot_02.png)

## ✨ Features

- 💻 Continue where you left off. Save and resume sessions with **Session Manager**. It uses mhinz/startify and mhinz/session. It loads a start screen by default.
- 🧹 Sane default settings for options, autocmds, and keymaps.
- 📦 Comes with a wealth of plugins pre-configured and ready to use.

## ⚡️ Requirements

- Neovim >= **0.12**
- A [Nerd Font](https://www.nerdfonts.com/) **_(recommended)_**

## 🚀 Getting Started

1. Find your nvim configuration directory.
2. Delete all files in that directory.
3. Clone this repository into that directory.

> [!IMPORTANT]
> You must manually clone the mini.nvim repository in `{stdpath('data')}/site/pack/core/start/`. Other plugins are automatically installed in {stdpath('data')}/site/pack/core/opt/.

## 📂 File Structure

This project follows a modular structure, separating core configuration from plugin-specific logic.

<pre>
~/.config/nvim
├── 📂 <b>colors</b>/              # Custom colorschemes and generators
│   ├── miniautumn.lua
│   ├── minispring.lua
│   └── neovim_colors.lua
├── 📂 <b>lua</b>/
│   ├── 📂 <b>config</b>/          # Core configuration
│   │   ├── autocmds.lua    # Automatic command definitions
│   │   ├── keymaps.lua     # Global keybindings
│   │   ├── mini.lua        # mini.nvim initialization
│   │   └── options.lua     # Vim options and variables
│   └── 📂 <b>plugins</b>/         # Modular plugin configs
│       ├── 📂 <b>code_style</b>/  # Formatting and linting
│       ├── 📂 <b>fold_this</b>/   # Advanced folding logic
│       ├── 📂 <b>qdtb</b>/        # Custom utility scripts
│       └── 📂 <b>session_manager</b>/ # Dashboard and sessions
├── init.lua                # Main entry point
└── nvim-pack-lock.json     # Plugin lockfile
</pre>
