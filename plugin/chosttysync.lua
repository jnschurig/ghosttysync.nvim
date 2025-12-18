-- ChosttySync plugin entry point
-- This file is automatically loaded by Neovim when the plugin is installed

-- Prevent loading the plugin multiple times
if vim.g.loaded_chosttysync then
  return
end
vim.g.loaded_chosttysync = 1

-- The actual plugin logic is in lua/chosttysync/init.lua
-- Users will call require('chosttysync').setup() to initialize the plugin