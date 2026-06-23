-- =========================
-- LEADER
-- ustawiamy przed pluginami i mappingami
-- =========================
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local map = vim.keymap.set

-- =========================
-- PLUGINS (vim-plug)
-- =========================
vim.cmd([[
call plug#begin()

Plug 'stevearc/oil.nvim'
Plug 'bngarren/checkmate.nvim'

" Telescope
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim', { 'tag': '0.1.8' }

" UI
Plug 'nvim-lualine/lualine.nvim'

" Git
Plug 'lewis6991/gitsigns.nvim'

" Commenting
Plug 'numToStr/Comment.nvim'

call plug#end()
]])

-- =========================
-- BASIC OPTIONS
-- =========================
vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.clipboard = "unnamedplus"
vim.opt.scrolloff = 10
vim.opt.backspace = { "indent", "eol", "start" }

vim.opt.encoding = "utf-8"
vim.opt.termguicolors = true

vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
-- vim.opt.expandtab = true -- odkomentuj, jeśli chcesz spacje zamiast tabów

vim.opt.wildmenu = true
vim.opt.incsearch = true

vim.opt.backup = false
vim.opt.swapfile = false
vim.opt.writebackup = false
vim.opt.undofile = false

vim.opt.guicursor = "v-i:block"

-- =========================
-- MAPPINGS
-- =========================
map("n", "<Space>", "<Nop>", { silent = true, desc = "Disable Space" })

map("n", "Y", "y$", { desc = "Yank to end of line" })

map("v", "<", "<gv", { desc = "Indent left and keep selection" })
map("v", ">", ">gv", { desc = "Indent right and keep selection" })

map("n", "zj", "o<Esc>k", { desc = "Insert empty line below" })
map("n", "zk", "O<Esc>j", { desc = "Insert empty line above" })

map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down centered" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up centered" })

map("n", "<M-h>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
map("n", "<M-l>", "<cmd>bnext<CR>", { desc = "Next buffer" })

map("n", "<leader>w", "<cmd>write<CR>", { desc = "Save file" })
map("n", "<leader>c", "<cmd>bdelete<CR>", { desc = "Close buffer" })
map("n", "<leader>c!", "<cmd>bdelete!<CR>", { desc = "Force close buffer" })
map("n", "<leader>h", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

map("n", "<leader>rr", "<cmd>source %<CR>", { desc = "Reload current file" })

-- =========================
-- HIGHLIGHT YANK
-- =========================
local yank_group = vim.api.nvim_create_augroup("HighlightYank", { clear = true })

vim.api.nvim_create_autocmd("TextYankPost", {
group = yank_group,
callback = function()
vim.highlight.on_yank({
higroup = "IncSearch",
timeout = 150,
})
end,
})

-- =========================
-- OIL
-- =========================
local oil_ok, oil = pcall(require, "oil")

if oil_ok then
oil.setup()

map("n", "<leader>e", "<cmd>Oil<CR>", { desc = "Open Oil" })
end

-- =========================
-- LUALINE
-- =========================
local lualine_ok, lualine = pcall(require, "lualine")

if lualine_ok then
lualine.setup({
options = {
theme = "auto",
globalstatus = true,
icons_enabled = false,
component_separators = "|",
section_separators = "",
},
})
end

-- =========================
-- GITSIGNS
-- =========================
local gitsigns_ok, gitsigns = pcall(require, "gitsigns")

if gitsigns_ok then
gitsigns.setup({
signs = {
add = { text = "+" },
change = { text = "~" },
delete = { text = "_" },
topdelete = { text = "‾" },
changedelete = { text = "~" },
},
})

map("n", "]g", "<cmd>Gitsigns next_hunk<CR>", {
desc = "Next git hunk",
})

map("n", "[g", "<cmd>Gitsigns prev_hunk<CR>", {
desc = "Previous git hunk",
})

map("n", "<leader>gp", "<cmd>Gitsigns preview_hunk<CR>", {
desc = "Preview git hunk",
})

map("n", "<leader>gb", "<cmd>Gitsigns blame_line<CR>", {
desc = "Git blame line",
})

map("n", "<leader>gr", "<cmd>Gitsigns reset_hunk<CR>", {
desc = "Reset git hunk",
})

map("v", "<leader>gr", "<cmd>Gitsigns reset_hunk<CR>", {
desc = "Reset selected git hunk",
})
end

-- =========================
-- COMMENT
-- =========================
local comment_ok, comment = pcall(require, "Comment")

if comment_ok then
comment.setup()
end

-- =========================
-- TELESCOPE
-- =========================
local telescope_ok, telescope = pcall(require, "telescope")

if telescope_ok then
local actions = require("telescope.actions")

telescope.setup({
defaults = {
mappings = {
i = {
["<C-j>"] = actions.move_selection_next,
["<C-k>"] = actions.move_selection_previous,
["<Esc>"] = actions.close,
},
n = {
["q"] = actions.close,
},
},
},
})

local builtin = require("telescope.builtin")

map("n", "<leader>ff", builtin.find_files, {
desc = "Find files",
})

map("n", "<leader>fg", builtin.live_grep, {
desc = "Live grep",
})

map("n", "<leader>fb", builtin.buffers, {
desc = "Find buffers",
})

map("n", "<leader>fh", builtin.help_tags, {
desc = "Find help",
})

map("n", "<leader>fr", builtin.oldfiles, {
desc = "Recent files",
})

map("n", "<leader>fc", builtin.commands, {
desc = "Find commands",
})

map("n", "<leader>fk", builtin.keymaps, {
desc = "Find keymaps",
})
end

-- =========================
-- CHECKMATE TODO
-- =========================
local checkmate_ok, checkmate = pcall(require, "checkmate")

if checkmate_ok then
checkmate.setup({
enabled = true,
notify = true,

files = {
  "*.md",
  "todo",
  "TODO",
  "todo.md",
  "TODO.md",
  "*.todo",
  "*.todo.md",
},

default_list_marker = "-",

todo_states = {
  unchecked = {
    marker = "○",
    order = 1,
  },

  in_progress = {
    marker = "◉",
    markdown = "/",
    type = "incomplete",
    order = 2,
  },

  checked = {
    marker = "●",
    order = 3,
  },
},

keys = {
  ["<leader>tt"] = {
    rhs = "<cmd>Checkmate cycle_next<CR>",
    desc = "Cycle TODO state",
    modes = { "n", "v" },
  },

  ["<leader>tT"] = {
    rhs = "<cmd>Checkmate cycle_previous<CR>",
    desc = "Cycle TODO state backwards",
    modes = { "n", "v" },
  },

  ["<leader>td"] = {
    rhs = "<cmd>Checkmate check<CR>",
    desc = "Mark TODO done",
    modes = { "n", "v" },
  },

  ["<leader>tu"] = {
    rhs = "<cmd>Checkmate uncheck<CR>",
    desc = "Mark TODO undone",
    modes = { "n", "v" },
  },

  ["<leader>tn"] = {
    rhs = "<cmd>Checkmate create<CR>",
    desc = "Create TODO",
    modes = { "n", "v" },
  },

  ["<leader>tr"] = {
    rhs = "<cmd>Checkmate remove<CR>",
    desc = "Remove TODO marker",
    modes = { "n", "v" },
  },

  ["<leader>ta"] = {
    rhs = "<cmd>Checkmate archive<CR>",
    desc = "Archive completed TODOs",
    modes = { "n" },
  },
},

list_continuation = {
  enabled = true,
  split_line = true,
},

})
end

-- =========================
-- SHORTCUTS SUMMARY
-- =========================
-- Space w    -> zapisz plik
-- Space c    -> zamknij buffer
-- Space c!   -> zamknij buffer na siłę
-- Space h    -> usuń highlight szukania
-- Space rr   -> przeładuj aktualny plik
-- Space e    -> Oil file explorer

-- Telescope:
-- Space f f  -> szukaj plików
-- Space f g  -> szukaj tekstu w projekcie
-- Space f b  -> bufory
-- Space f h  -> help
-- Space f r  -> ostatnie pliki
-- Space f c  -> komendy
-- Space f k  -> keymapy

-- GitSigns:
-- ] g        -> następna zmiana git
-- [ g        -> poprzednia zmiana git
-- Space g p  -> podgląd zmiany
-- Space g b  -> blame aktualnej linii
-- Space g r  -> cofnij zmianę/hunk

-- Comment:
-- g c c      -> zakomentuj/odkomentuj linię
-- g c        -> zakomentuj/odkomentuj zaznaczenie w visualu

-- Checkmate:
-- Space t n  -> nowe TODO
-- Space t t  -> todo -> in progress -> done
-- Space t T  -> wstecz
-- Space t d  -> done
-- Space t u  -> undone
-- Space t r  -> usuń checkbox
-- Space t a  -> archiwum done
