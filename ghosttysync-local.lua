-- Local development version of GhosttySync configuration
-- Use this if you're testing the plugin locally before it's published

return {
  dir = "/path/to/your/ghosttysync/plugin", -- Update this path to your local plugin directory
  name = "ghosttysync.nvim",
  lazy = false,
  priority = 1000, -- Load before other colorscheme plugins
  config = function()
    -- Add the plugin to Lua path if testing locally
    local plugin_path = "/path/to/your/ghosttysync/plugin" -- Update this path
    if not string.find(package.path, plugin_path, 1, true) then
      package.path = package.path .. ";" .. plugin_path .. "/?.lua;" .. plugin_path .. "/?/init.lua"
    end
    
    require("ghosttysync").setup({
      -- Enable automatic theme synchronization on startup
      auto_sync = true,
      
      -- Cache timeout in seconds (30 seconds default)
      -- Helps performance by avoiding repeated Ghostty CLI calls
      cache_timeout = 30,
      
      -- Enable debug logging for troubleshooting
      -- Set to true if you want to see what the plugin is doing
      debug = true, -- Enable debug for local testing
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