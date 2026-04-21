<div align="center">
  <img src="https://user-images.githubusercontent.com/292349/213446185-2db63fd5-8c84-459c-9f04-e286382d6e80.png">
</div>

<hr>

<h4 align="center">
  Modular · Fast · Native
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
      <img src="https://img.shields.io/badge/blog-latest_posts-orange?style=flat-square&logo=rss&logoColor=white" alt="Blog" />
    </a>
    <a href="https://natebass.github.io/qdtb-doc/docs">
      <img src="https://img.shields.io/badge/docs-qdtb-blue?style=flat-square&logo=docusaurus&logoColor=white" alt="Docs" />
    </a>
</p></div>

# QDtb Neovim Configuration

Welcome to my personal Neovim configuration. Built for speed and modularity, this setup leverages the native Neovim package system and `mini.nvim` for a lightweight yet powerful experience.

![image](https://user-images.githubusercontent.com/292349/211285846-0b7bb3bf-0462-4029-b64c-4ee1d037fc1c.png)

## ✨ Features

- 🚀 **Native Package Management**: Uses Neovim's built-in `packpath` for plugin loading, avoiding the overhead of external managers.
- 🎨 **Custom Aesthetics**: Includes handcrafted colorschemes like `MiniAutumn`, `MiniSpring`, and `MiniWinter`.
- 📖 **Enlightened Dashboard**: Startify-based dashboard featuring random Bible verses and algorithm quotes to keep you inspired.
- 🛠️ **Utility Suite**: Integrated tools for autosaving, window title management, and a dynamic colorscheme cycler.
- 📦 **Modular Design**: Configured with a clear separation of concerns between core options, keymaps, and plugin specifications.

## ⚡️ Requirements

- Neovim >= **0.12**
- A [Nerd Font](https://www.nerdfonts.com/) **_(recommended)_**

## 🚀 Getting Started

1. Backup your existing configuration.
2. Clone this repository into your Neovim configuration directory (usually `~/.config/nvim`).
3. Ensure `mini.nvim` is available in your `packpath`.

> [!IMPORTANT]
> This configuration relies on the native Neovim package architecture. Plugins should be placed in `{stdpath('data')}/site/pack/core/start/`.

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
