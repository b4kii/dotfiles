-- =========================
-- LEADER
-- musi byc przed pluginami i mappingami
-- =========================
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local map = vim.keymap.set

local function notify_error(name, err)
  vim.schedule(function()
    vim.notify(name .. " error: " .. tostring(err), vim.log.levels.ERROR)
  end)
end

local function safe_setup(name, fn)
  local ok, err = pcall(fn)
  if not ok then
    notify_error(name, err)
  end
end

-- =========================
-- PLUGINS (vim-plug)
-- =========================
safe_setup("vim-plug", function()
  vim.cmd([[
call plug#begin()

Plug 'stevearc/oil.nvim'
Plug 'bngarren/checkmate.nvim'
Plug '~/.config/nvim/plugins/worklog.nvim'

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
end)

-- =========================

-- =========================
-- WORKLOG TODO PLUGIN
-- =========================
safe_setup("worklog.nvim", function()
  require("worklog").setup()
end)

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
-- vim.opt.expandtab = true -- odkomentuj, jesli chcesz spacje zamiast tabow

vim.opt.wildmenu = true
vim.opt.incsearch = true

vim.opt.backup = false
vim.opt.swapfile = false
vim.opt.writebackup = false
vim.opt.undofile = false

vim.opt.guicursor = "v-i:block"

-- Checkmate dziala tylko na markdownach, wiec pliki "todo"/"TODO"
-- bez rozszerzenia ustawiamy automatycznie jako markdown.
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { "todo", "TODO", "*.todo", "*.todo.md" },
  callback = function()
    vim.bo.filetype = "markdown"
  end,
})

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

map("n", "<leader>rr", function()
  local config_file = vim.env.MYVIMRC

  if not config_file or config_file == "" then
    config_file = vim.fn.stdpath("config") .. "/init.lua"
  end

  vim.cmd("source " .. vim.fn.fnameescape(config_file))
  vim.notify("Reloaded Neovim config: " .. config_file, vim.log.levels.INFO)
end, {
  desc = "Reload Neovim config",
})

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
  safe_setup("oil.nvim", function()
    oil.setup()

    map("n", "<leader>e", "<cmd>Oil<CR>", {
      desc = "Open Oil",
    })
  end)
end

-- =========================
-- LUALINE
-- =========================
local lualine_ok, lualine = pcall(require, "lualine")

if lualine_ok then
  safe_setup("lualine.nvim", function()
    lualine.setup({
      options = {
        theme = "auto",
        globalstatus = true,
        icons_enabled = false,
        component_separators = "|",
        section_separators = "",
      },
    })
  end)
end

-- =========================
-- GITSIGNS
-- =========================
local gitsigns_ok, gitsigns = pcall(require, "gitsigns")

if gitsigns_ok then
  safe_setup("gitsigns.nvim", function()
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
  end)
end

-- =========================
-- COMMENT
-- =========================
local comment_ok, comment = pcall(require, "Comment")

if comment_ok then
  safe_setup("Comment.nvim", function()
    comment.setup()
  end)
end

-- =========================
-- TELESCOPE
-- =========================
local telescope_ok, telescope = pcall(require, "telescope")

if telescope_ok then
  safe_setup("telescope.nvim", function()
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
  end)
end

-- =========================
-- SHORTCUTS SUMMARY
-- =========================
-- Space w    -> zapisz plik
-- Space c    -> zamknij buffer
-- Space c!   -> zamknij buffer na sile
-- Space h    -> usun highlight szukania
-- Space rr   -> przeladuj aktualny plik
-- Space e    -> Oil file explorer

-- Telescope:
-- Space f f  -> szukaj plikow
-- Space f g  -> szukaj tekstu w projekcie
-- Space f b  -> bufory
-- Space f h  -> help
-- Space f r  -> ostatnie pliki
-- Space f c  -> komendy
-- Space f k  -> keymapy

-- GitSigns:
-- ] g        -> nastepna zmiana git
-- [ g        -> poprzednia zmiana git
-- Space g p  -> podglad zmiany
-- Space g b  -> blame aktualnej linii
-- Space g r  -> cofnij zmiane/hunk

-- Comment:
-- g c c      -> zakomentuj/odkomentuj linie
-- g c        -> zakomentuj/odkomentuj zaznaczenie w visualu

-- Custom TODO / Worklog:
-- Space j D  -> dodaj/przejdz do dzisiejszej sekcji # dd-mm-yyyy z separatorem ---------
-- Space j s  -> to samo co Space j D
-- Space j n  -> dodaj nowe TODO w aktualnym dniu albo globalnym ## TODO
-- Space j t  -> TODO -> IN PROGRESS @start -> ARCHIVE @start/@end/@lasted -> TODO w aktualnym dniu
-- Space j T  -> cykl wstecz w aktualnym dniu
-- Space j d  -> oznacz done, dodaj @end/@lasted na koncu i przenies do ARCHIVE w aktualnym dniu
-- Space j u  -> odznacz i przenies do TODO w aktualnym dniu
-- Space j r  -> usun checkbox
-- Space j a  -> recznie odswiez sekcje aktualnego dnia
-- Space j i  -> oznacz jako in progress, dodaj @start na koncu i przenies do IN PROGRESS w aktualnym dniu
-- Space k a -> dodaj albo zaktualizuj @tag(value) na aktualnej linii
-- Space k t -> toggle @tag(value) na aktualnej linii
-- Space k r -> usun @tag(value) pod kursorem albo po nazwie taga
-- Space k R -> usun user tagi z linii, ale zostaw @start/@end/@lasted
-- Space k v -> edytuj value taga pod kursorem bez okna Telescope
-- Space k ] -> nastepny tag metadata
-- Space k [ -> poprzedni tag metadata

-- Komendy:
-- :TodoToday
-- :TodoCreate
-- :TodoNormalizeSections
-- :TodoMoveInProgress
-- :TodoCreateInProgress
