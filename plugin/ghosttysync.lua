-- GhosttySync plugin entry point
-- This file is automatically loaded by Neovim when the plugin is installed

-- Prevent loading the plugin multiple times
if vim.g.loaded_ghosttysync then
  return
end
vim.g.loaded_ghosttysync = 1

-- The actual plugin logic is in lua/ghosttysync/init.lua
-- Users will call require('ghosttysync').setup() to initialize the plugin