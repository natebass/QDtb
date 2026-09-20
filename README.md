<div align="center">
  <img src="https://github.com/natebass/QDtb-doc/blob/master/documentation/static/img/logo.jpeg" alt="QDtb project Logo"/>
</div>

<hr>

<h4 align="center">
  <a href="https://natebass.github.io/QDtb-doc/docs">Install</a>
  ·
  <a href="https://natebass.github.io/QDtb-doc">Docs</a>
</h4>

<div align="center"><p>
    <a href="https://github.com/natebass/QDtb/pulse">
      <img alt="Last commit" src="https://img.shields.io/github/last-commit/natebass/QDtb?style=for-the-badge&logo=starship&color=8bd5ca&logoColor=D9E0EE&labelColor=302D41"/>
    </a>
    <a href="https://github.com/natebass/QDtb/blob/master/LICENSE">
      <img alt="License" src="https://img.shields.io/github/license/natebass/QDtb?style=for-the-badge&logo=starship&color=ee999f&logoColor=D9E0EE&labelColor=302D41" />
    </a>
    <a href="https://github.com/natebass/QDtb/stargazers">
      <img alt="Stars" src="https://img.shields.io/github/stars/natebass/QDtb?style=for-the-badge&logo=starship&color=c69ff5&logoColor=D9E0EE&labelColor=302D41" />
    </a>
    <a href="https://natebass.github.io/QDtb-doc/blog">
      <img src="https://img.shields.io/badge/blog-latest_posts-orange?style=for-the-badge&logo=rss&logoColor=white" alt="Blog" />
    </a>
</p></div>

# QDtb Neovim configuration

Welcome to my personal Neovim configuration. It is partly based on [💤 lazy.nvim](https://github.com/folke/lazy.nvim) and uses many [mini.nvim](https://github.com/nvim-mini/mini.nvim) plugins.

## ✨ Features

- 💻 Continue where you left off. Save and resume sessions with **Session Manager**. It uses mhinz/startify and mhinz/session.

## Requirements

- Neovim >= **0.12**
- A [Nerd Font](https://www.nerdfonts.com/) **_(recommended)_**

## Install

Clone into `stdpath("config")`.

## Local data directory

This project uses the native NVIM package manager.

- `vim.pack.add(..., { load = false })` installs missing packages and uses
  `nvim-pack-lock.json` without sourcing every optional plugin during
  startup.
- Packages are stored under `site/pack/core/opt/` and loaded only when needed
  with Neovim's built-in `:packadd` command.
- Command-oriented plugins are loaded when their command is first used
  (`:NERDTree`, `:Goyo`, `:Limelight`, `:Startify`, and `:TZNarrow`).
- Copilot loads on first Insert mode entry and WakaTime after `VimEnter`.
- `mini.nvim` uses `vim.pack.add(..., { load = false }) to load immediately on startup.

On startup, Neovim prompts to install the missing packages. 

To update, run `:lua vim.pack.update()` and then `:w` in the resulting buffer to save changes to `nvim-pack-lock.json`.

## Resources

- The QDtb documentation repository https://github.com/natebass/QDtb-doc.
