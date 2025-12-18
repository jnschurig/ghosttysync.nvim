return {
  "jnschurig/ghosttysync.nvim", -- Correct repo name
  lazy = false,
  priority = 1000, -- Load before other colorscheme plugins
  config = function()
    require("ghosttysync").setup({
      -- Enable automatic theme synchronization on startup
      auto_sync = true,
      
      -- Cache timeout in seconds (0 = no caching, always fresh)
      -- Set to 0 to always recalculate theme on every sync
      cache_timeout = 0,
      
      -- Enable debug logging for troubleshooting
      -- Set to true if you want to see what the plugin is doing
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