-- ===========================================================================
--  init.lua  --  Neovim >= 0.12   (Linux / macOS / Windows)
--
--  Plugin manager: vim.pack -- BUILT INTO Neovim 0.12.
--  There is nothing to bootstrap. Missing plugins clone themselves on the
--  first start. The only external requirement is `git` in PATH.
--
--    :h vim.pack              -- documentation
--    :lua vim.pack.update()   -- update (:w applies, :q discards)
--    :lua vim.pack.del({'x'}) -- remove a plugin from disk
--
--  State is kept in a lockfile (nvim-pack-lock.json in stdpath('state')), so
--  the same revisions can be reproduced on any machine.
-- ===========================================================================

if vim.fn.has('nvim-0.12') == 0 then
  vim.api.nvim_echo({
    { 'This config requires Neovim 0.12+ (vim.pack). You have: ', 'ErrorMsg' },
    { tostring(vim.version()), 'ErrorMsg' },
  }, true, { err = true })
  return
end

-- Cache skompilowanego bajtkodu Lua. 76% startu to `require()`, a bez tego
-- kazdy modul jest parsowany od nowa przy kazdym uruchomieniu. Zmierzone na
-- tej maszynie: 220 ms -> 185 ms. Musi byc PRZED pierwszym require.
-- Cache sam wykrywa zmiany plikow; recznie czysci go vim.loader.reset().
vim.loader.enable()

-- leader MUST be set before plugins load
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- do you have a Nerd Font installed? false = lualine/oil without icons
vim.g.have_nerd_font = true

require('options')
require('plugins')
require('keymaps')
require('autocmds')
require('lsp') -- delete this line if you do not want LSP
