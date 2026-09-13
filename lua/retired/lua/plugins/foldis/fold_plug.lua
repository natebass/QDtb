function M.setup()
    -- Set fillchars to remove the vertical line guide for folds.
    -- This creates a cleaner, less cluttered look.
    vim.o.fillchars = 'fold: '

    -- Create a dedicated autocommand group to ensure our settings don't
    -- conflict with other plugins.
    local group = vim.api.nvim_create_augroup('CustomFolds', { clear = true })

    -- Create an autocommand that runs whenever a buffer is entered into a window.
    -- This applies our folding settings on a per-window basis.
    vim.api.nvim_create_autocmd('BufWinEnter', {
        group = group,
        pattern = 'lua',
        desc = 'Apply custom folding settings',
        callback = function()
            -- We use window-local options (vim.wo) because folding settings
            -- are specific to each window, not the buffer itself.
            -- This was the source of the previous error.

            -- Set fold method to 'expr'. This is required to use a custom fold expression.
            vim.wo.foldmethod = 'expr'
            -- Use the Tree-sitter fold expression.
            -- NOTE: This requires nvim-treesitter to be installed and configured.
            vim.wo.foldexpr = 'nvim_treesitter#foldexpr()'
            -- Set our custom function to render the fold text.
            vim.wo.foldtext = 'v:lua.require('fold-plug').fold_text()'
            -- Start with all folds open when a file is loaded.
            vim.wo.foldlevelstart = 99
            -- Ensure folding is enabled for the window.
            vim.wo.foldenable = true
        end,
    })

    vim.notify('fold-plug: Custom folding enabled.', vim.log.levels.INFO)
end

return M
