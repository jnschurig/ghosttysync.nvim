return {
  "jnschurig/ghosttysync.nvim", -- Correct repo name
  lazy = false,
  priority = 1000, -- Load before other colorscheme plugins
  config = function()
    require("chosttysync").setup({
      -- Enable automatic theme synchronization on startup
      auto_sync = true,
      
      -- Cache timeout in seconds (30 seconds default)
      -- Helps performance by avoiding repeated Ghostty CLI calls
      cache_timeout = 30,
      
      -- Enable debug logging for troubleshooting
      -- Set to true if you want to see what the plugin is doing
      debug = false,
    })
    
    -- Optional: Set up keymaps for manual control
    vim.keymap.set('n', '<leader>ts', ':ChosttySyncTheme<CR>', { 
      desc = 'Sync Ghostty theme with Neovim',
      silent = true 
    })
    
    vim.keymap.set('n', '<leader>td', ':ChosttySyncDebug<CR>', { 
      desc = 'Toggle ChosttySync debug mode',
      silent = true 
    })
    
    vim.keymap.set('n', '<leader>tt', ':ChosttySyncStatus<CR>', { 
      desc = 'Show ChosttySync status',
      silent = true 
    })
  end,
}