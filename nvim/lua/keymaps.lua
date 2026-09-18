-- ===========================================================================
--  keymaps.lua -- carried over 1:1 from your init.vim
--
--  Plugin keymaps are NOT here -- they live next to each plugin's setup in
--  lua/plugins.lua, so removing a plugin takes its keys with it.
-- ===========================================================================

local map = vim.keymap.set

-- <space> as leader (`mapleader` itself is set in init.lua)
map({ 'n', 'v' }, '<Space>', '<Nop>')

-- Neovim maps Y -> y$ by default since 0.6, so this line changes nothing.
-- Kept for parity with your old config; safe to delete.
map('n', 'Y', 'y$')

-- keep the selection after indenting
map('v', '<', '<gv', { desc = 'Indent left, keep selection' })
map('v', '>', '>gv', { desc = 'Indent right, keep selection' })

-- blank line below/above without entering insert mode
map('n', 'zj', 'o<Esc>k', { desc = 'Blank line below' })
map('n', 'zk', 'O<Esc>j', { desc = 'Blank line above' })

-- scroll with the cursor centered
map('n', '<C-d>', '<C-d>zz', { desc = 'Half page down, centered' })
map('n', '<C-u>', '<C-u>zz', { desc = 'Half page up, centered' })

-- buffers (on macOS needs "Use Option as Meta key" in the terminal settings)
map('n', '<M-h>', '<Cmd>bp<CR>', { desc = 'Buffer: previous' })
map('n', '<M-l>', '<Cmd>bn<CR>', { desc = 'Buffer: next' })

map('n', '<leader>w', '<Cmd>w<CR>', { desc = 'Write file' })
map('n', '<leader>q', '<Cmd>bd<CR>', { desc = 'Close buffer' })
map('n', '<leader>h', '<Cmd>nohlsearch<CR>', { desc = 'Clear search highlight' })

-- jumps within a line / file
map({ 'n', 'v' }, '<leader>gh', '0', { desc = 'Goto: line start' })
map({ 'n', 'v' }, '<leader>gl', '$', { desc = 'Goto: line end' })
map({ 'n', 'v' }, '<leader>ge', 'G', { desc = 'Goto: end of file' })

-- re-source the current config file
map('n', '<leader>rr', '<Cmd>source %<CR>', { desc = 'Reload: source this file' })
