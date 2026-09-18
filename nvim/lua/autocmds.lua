-- ===========================================================================
--  autocmds.lua
-- ===========================================================================

-- Your highlight_yank augroup. `vim.highlight` is deprecated since 0.11; the
-- replacement is `vim.hl`.
vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('highlight_yank', { clear = true }),
  desc = 'Highlight yanked text',
  callback = function()
    vim.hl.on_yank({ higroup = 'IncSearch', timeout = 150 })
  end,
})

-- Indent width per language.
--
-- The global setting (4 columns, hard tabs) comes from your init.vim and stays
-- the default. But two levels of hard tabs in an HTML file render 8 columns
-- wide, which is why nesting looked absurd. These are the widths the
-- respective communities and prettier actually use, so formatting with
-- <leader>cf no longer fights the editor.
local indent_width = {
  [2] = {
    'html', 'htmldjango', 'css', 'scss', 'less', 'javascript', 'typescript',
    'javascriptreact', 'typescriptreact', 'vue', 'svelte',
    'json', 'jsonc', 'yaml', 'lua', 'markdown', 'xml',
  },
  [4] = { 'php', 'python', 'sh', 'bash', 'c', 'cpp', 'java', 'rust', 'go' },
}

local width_for = {}
for width, fts in pairs(indent_width) do
  for _, ft in ipairs(fts) do width_for[ft] = width end
end

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('indent_width', { clear = true }),
  desc = 'Per-language indent width',
  callback = function(args)
    local w = width_for[args.match]
    if not w then return end
    vim.bo[args.buf].shiftwidth = w
    vim.bo[args.buf].softtabstop = w
    vim.bo[args.buf].tabstop = w
    -- Spaces, not tabs, for everything listed here. `go` is the one language
    -- above that genuinely wants tabs, so it keeps them.
    vim.bo[args.buf].expandtab = args.match ~= 'go'
  end,
})

-- Neovim's php ftplugin sets commentstring to `/* %s */`, so `gcc` wraps a
-- single line in a block comment. `//` is what PHP code actually uses.
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('commentstring_overrides', { clear = true }),
  pattern = { 'php' },
  desc = 'Use // for line comments instead of /* */',
  callback = function()
    vim.bo.commentstring = '// %s'
  end,
})
