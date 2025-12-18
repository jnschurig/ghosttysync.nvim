-- Minimal GhosttySync configuration
-- Just the essentials for automatic Ghostty theme synchronization

return {
  "your-username/ghosttysync.nvim", -- Replace with actual plugin path when published
  lazy = false,
  priority = 1000,
  config = function()
    -- Simple setup with defaults
    require("ghosttysync").setup()
  end,
}