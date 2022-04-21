local opts = { noremap = true, silent = true }
local map = vim.api.nvim_set_keymap

-- Remapping leader key
map("", "<space>", "<nop>", opts)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Remapping esc key
map("n", "qf", "<esc>", opts)
map("i", "qf", "<esc>", opts)
map("v", "qf", "<esc>", opts)
map("x", "qf", "<esc>", opts)
map("s", "qf", "<esc>", opts)

-- Other personal remaps

map("n", "<leader>h", "<cmd>nohl<cr>", opts)
map("n", "<leader>o", "o<esc>k", opts)
map("n", "<leader>w", "<cmd>w<cr>", opts)
map("n", "Y", "y$", opts)

-- Indent
map("v", "<", "<gv", opts)
map("v", ">", ">gv", opts)

-- Comments
map("n", "<leader>/", "<cmd>lua require('Comment.api').toggle_current_linewise()<cr>", opts)
map("v", "<leader>/", "<esc><cmd>lua require('Comment.api').toggle_linewise_op(vim.fn.visualmode())<CR>", opts)

-- Bufferline
map("n", "<S-l>", "<cmd>BufferLineCycleNext<cr>", opts)
map("n", "<S-h>", "<cmd>BufferLineCyclePrev<cr>", opts)

-- Buffers
map("n", "<leader>c", "<cmd>Bdelete<cr>", opts)

-- Windows navigation
map("n", "<c-h>", "<c-w>h", opts)
map("n", "<c-j>", "<c-w>j", opts)
map("n", "<c-k>", "<c-w>k", opts)
map("n", "<c-l>", "<c-w>l", opts)

-- Telescope
map("n", "<leader>fw", "<cmd>Telescope live_grep<CR>", opts) -- ripgrep required https://github.com/BurntSushi/ripgrep
map("n", "<leader>gt", "<cmd>Telescope git_status<CR>", opts)
map("n", "<leader>gb", "<cmd>Telescope git_branches<CR>", opts)
map("n", "<leader>gc", "<cmd>Telescope git_commits<CR>", opts)
map("n", "<leader>ff", "<cmd>Telescope find_files<CR>", opts)
map("n", "<leader>fb", "<cmd>Telescope buffers<CR>", opts)
map("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", opts)
map("n", "<leader>fo", "<cmd>Telescope oldfiles<CR>", opts)
map("n", "<leader>sb", "<cmd>Telescope git_branches<CR>", opts)
map("n", "<leader>sh", "<cmd>Telescope help_tags<CR>", opts)
map("n", "<leader>sm", "<cmd>Telescope man_pages<CR>", opts)
map("n", "<leader>sn", "<cmd>Telescope notify<CR>", opts)
map("n", "<leader>sr", "<cmd>Telescope registers<CR>", opts)
map("n", "<leader>sk", "<cmd>Telescope keymaps<CR>", opts)
map("n", "<leader>sc", "<cmd>Telescope commands<CR>", opts)
map("n", "<leader>ls", "<cmd>Telescope lsp_document_symbols<CR>", opts)
map("n", "<leader>lR", "<cmd>Telescope lsp_references<CR>", opts)
map("n", "<leader>lD", "<cmd>Telescope diagnostics<CR>", opts)

-- LSP
map("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", opts)
map("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
map("n", "gI", "<cmd>lua vim.lsp.buf.implementation()<CR>", opts)
map("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", opts)
map("n", "go", "<cmd>lua vim.diagnostic.open_float()<CR>", opts)
map("n", "gl", "<cmd>lua vim.diagnostic.open_float()<CR>", opts)
map("n", "[d", "<cmd>lua vim.diagnostic.goto_prev({ border = 'rounded' })<CR>", opts)
map("n", "]d", "<cmd>lua vim.diagnostic.goto_next({ border = 'rounded' })<CR>", opts)
map("n", "gj", "<cmd>lua vim.diagnostic.goto_next({ border = 'rounded' })<cr>", opts)
map("n", "gk", "<cmd>lua vim.diagnostic.goto_prev({ border = 'rounded' })<cr>", opts)
map("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)

-- Floaterm
map("n", "<C-t>", "<cmd>FloatermToggle<cr><C-\\><C-n><CR>", opts)
map("t", "<C-t>", "<C-\\><C-n><cmd>FloatermToggle<cr>", opts)

-- NvimTree
map("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", opts)
map("n", "<leader>z", "<cmd>NvimTreeFocus<CR>", opts)

-- Gitsigns
map("n", "<leader>gj", "<cmd>lua require 'gitsigns'.next_hunk()<cr>", opts)
map("n", "<leader>gk", "<cmd>lua require 'gitsigns'.prev_hunk()<cr>", opts)
map("n", "<leader>gl", "<cmd>lua require 'gitsigns'.blame_line()<cr>", opts)
map("n", "<leader>gp", "<cmd>lua require 'gitsigns'.preview_hunk()<cr>", opts)
map("n", "<leader>gh", "<cmd>lua require 'gitsigns'.reset_hunk()<cr>", opts)
map("n", "<leader>gr", "<cmd>lua require 'gitsigns'.reset_buffer()<cr>", opts)
map("n", "<leader>gs", "<cmd>lua require 'gitsigns'.stage_hunk()<cr>", opts)
map("n", "<leader>gu", "<cmd>lua require 'gitsigns'.undo_stage_hunk()<cr>", opts)
map("n", "<leader>gd", "<cmd>Gitsigns diffthis HEAD<cr>", opts)

-- Packer
map("n", "<leader>pc", "<cmd>PackerCompile<cr>", opts)
map("n", "<leader>pi", "<cmd>PackerInstall<cr>", opts)
map("n", "<leader>ps", "<cmd>PackerSync<cr>", opts)
map("n", "<leader>pS", "<cmd>PackerStatus<cr>", opts)
map("n", "<leader>pu", "<cmd>PackerUpdate<cr>", opts)
