-- ===========================================================================
--  options.lua -- carried over 1:1 from your init.vim + the minimum plugins
--  need
-- ===========================================================================

local o = vim.o

-- --- your settings ---------------------------------------------------------
o.relativenumber = true
o.scrolloff = 10
o.backspace = 'indent,eol,start'

-- Your `v-i:block`, kept, but every mode now also names the `Cursor` highlight
-- group -- without a group attached there is nothing to colour. The group
-- itself is defined in lua/plugins.lua, next to the colorscheme.
o.guicursor = 'n-v-c-sm:block-Cursor,i-ci-ve:block-Cursor,r-cr-o:hor20-Cursor'
o.tabstop = 4
o.shiftwidth = 4
o.softtabstop = 4
o.wildmenu = true
o.incsearch = true

-- --- completion popup size -------------------------------------------------
-- Both default to 0, which means "no limit", so a language server that returns
-- a few thousand symbols paints the menu over the entire screen.
o.pumheight = 12   -- max visible entries; the rest scrolls
o.pummaxwidth = 60 -- max width of the menu itself (pumwidth 15 is the minimum)
o.backup = false
o.writebackup = false
o.swapfile = false
o.undofile = false

-- `set encoding=utf-8` dropped: Neovim is always UTF-8, the option is a no-op.

-- --- clipboard (cross-platform) --------------------------------------------
-- OSC52 goes through the terminal, so it is the only sane choice over SSH.
-- Locally the native provider (clip.exe / pbcopy / wl-copy / xclip) is better:
-- it also handles PASTING, which OSC52 cannot do in most terminals.
if vim.env.SSH_TTY or vim.env.SSH_CONNECTION then
  vim.g.clipboard = 'osc52'
end
-- want OSC52 everywhere, like the old config? replace the block above with:
--   vim.g.clipboard = 'osc52'
o.clipboard = 'unnamedplus'

-- No `packadd matchit` here: Neovim's own plugin/matchit.vim already does it,
-- so `%` jumps between <div> and </div> out of the box. The catch is that
-- b:match_words matches the tag NAME (the pattern uses a `<\@<=` lookbehind),
-- so the cursor has to sit on `div`, not on the `<`.

-- --- required by plugins ---------------------------------------------------
-- Reserve the sign column so text does not jump sideways when gitsigns, LSP
-- diagnostic or todo-comments signs appear.
o.signcolumn = 'yes'

-- --- optional (uncomment if you want them) ---------------------------------
-- o.number = true          -- current line number instead of "0"
-- o.ignorecase = true      -- case-insensitive search...
-- o.smartcase = true       -- ...unless you type an uppercase letter
-- o.expandtab = true       -- spaces instead of hard tabs
-- o.splitright = true
-- o.splitbelow = true
-- o.winborder = 'rounded'  -- 0.11+: borders around floating windows (LSP hover)
