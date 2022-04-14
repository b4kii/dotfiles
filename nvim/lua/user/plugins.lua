local fn = vim.fn

local install_path = fn.stdpath "data" .. "/site/pack/packer/start/packer.nvim"
if fn.empty(fn.glob(install_path)) > 0 then
  PACKER_BOOTSTRAP = fn.system {
    "git",
    "clone",
    "--depth",
    "1",
    "https://github.com/wbthomason/packer.nvim",
    install_path,
  }
  print "Installing packer close and reopen Neovim..."
  vim.cmd [[packadd packer.nvim]]
end

vim.cmd [[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile> | PackerSync
  augroup end
]]

local statusk_ok, packer = pcall(require, 'packer')
if not statusk_ok then
    return
end

packer.init {
  display = {
    open_fn = function()
      return require("packer.util").float { border = "rounded" }
    end,
  },
}

return require('packer').startup(
    function(use)

        -- Packer can manage itself
        use {
            'wbthomason/packer.nvim'
        }

        use {
            'nvim-lua/plenary.nvim',
            'nvim-lua/popup.nvim'
        }

        -- Theme
        use {
            'Shatur/neovim-ayu'
        }

        -- Bufferline
        use {
            'akinsho/bufferline.nvim',
            config = function()
                require('bufferline').setup()
            end
        }

        -- Statusline
        use {
            'nvim-lualine/lualine.nvim',
            require('lualine').setup({
                options = {theme = 'ayu'},
            })
        }

        -- Icons
        use {
            'kyazdani42/nvim-web-devicons'
        }

        -- Telescope
        use {
            'nvim-telescope/telescope.nvim',
            requires = { {'nvim-lua/plenary.nvim'} }
        }

        -- Autopairs
        use {
            'windwp/nvim-autopairs',
            require('user.autopairs').config()
        }

        -- Terminal
        use {
            'voldikss/vim-floaterm'
        }

        -- Commenting
        use {
            'numToStr/Comment.nvim',
            config = function()
                require('Comment').setup()
            end
        }

        -- Multiple cursor
        use {
            'terryma/vim-multiple-cursors'
        }

        -- NvimTree
        use {
            'kyazdani42/nvim-tree.lua',
            cmd = { 'NvimTreeToggle', 'NvimTreeFocus' },
            requires = {
              'kyazdani42/nvim-web-devicons', -- optional, for file icon
            },
            config = function ()
                require('user.nvim-tree').config()
            end,
        }

        -- Cmp plugins
        use {
            'hrsh7th/nvim-cmp',
            'hrsh7th/cmp-buffer',
            'hrsh7th/cmp-path',
            'hrsh7th/cmp-cmdline',
            'hrsh7th/cmp-nvim-lsp',
            'hrsh7th/cmp-nvim-lua',
            'saadparwaiz1/cmp_luasnip',
            require('user.cmp').config()
        }

        -- Snippets
        use {
            'L3MON4D3/LuaSnip',
            'rafamadriz/friendly-snippets'
        }

        -- Syntax highlighting
        use {
            'nvim-treesitter/nvim-treesitter',
            run = ':TSUpdate',
            event = 'BufRead',
            cmd = {
                'TSInstall',
                'TSInstallInfo',
                'TSInstallSync',
                'TSUninstall',
                'TSUpdate',
                'TSUpdateSync',
                'TSDisableAll',
                'TSEnableAll',
            },
            config = function()
                require('user.treesitter').config()
            end
        }

        -- Parenthesis highlighting
        use {
            'p00f/nvim-ts-rainbow',
            after = 'nvim-treesitter',
        }

        -- LSP manager
        use {
            'williamboman/nvim-lsp-installer'
        }

        -- Built in LSP
        use {
            'neovim/nvim-lspconfig'
        }

        -- Extra JSON schemas
        use {
             'b0o/SchemaStore.nvim'
        }

        -- Git signs
        use {
            'lewis6991/gitsigns.nvim',
        }

        -- Autoclose tags
        use {
            'windwp/nvim-ts-autotag',
            after = 'nvim-treesitter'
        }
        if PACKER_BOOTSTRAP then
            require("packer").sync()
        end
    end
)
