-- GhosttySync configuration for the ghosttysync.nvim repository
-- Handles the naming mismatch between repo name and module name

return {
  "jnschurig/ghosttysync.nvim",
  branch = "v0", -- Specify the branch you want
  lazy = false,
  priority = 1000,
  config = function()
    -- The module is still named 'ghosttysync' internally
    require("ghosttysync").setup({
      -- Enable automatic theme synchronization on startup
      auto_sync = true,
      
      -- Cache timeout in seconds (30 seconds default)
      cache_timeout = 30,
      
      -- Enable debug logging for troubleshooting
      debug = false,
    })
    
    -- Optional: Set up keymaps for manual control
    vim.keymap.set('n', '<leader>ts', ':GhosttySyncTheme<CR>', { 
      desc = 'Sync Ghostty theme with Neovim',
      silent = true 
    })
    
    vim.keymap.set('n', '<leader>td', ':GhosttySyncDebug<CR>', { 
      desc = 'Toggle GhosttySync debug mode',
      silent = true 
    })
    
    vim.keymap.set('n', '<leader>tt', ':GhosttySyncStatus<CR>', { 
      desc = 'Show GhosttySync status',
      silent = true 
    })
  end,
}