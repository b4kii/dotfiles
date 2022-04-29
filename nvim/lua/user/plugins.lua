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
            require('user.bufferline').config()
          end
        }

        -- Better buffer closing
        use {
          'moll/vim-bbye',
        }

        -- Statusline
        use {
          'nvim-lualine/lualine.nvim',
          config = function()
              require('user.lualine').config()
          end
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
          config = function()
              require('user.autopairs').config()
          end
        }

        -- Terminal
        use {
          'voldikss/vim-floaterm'
        }

        -- Commenting
        use {
          'numToStr/Comment.nvim',
          config = function()
            require('user.comment').config()
          end
        }

        use {
          'JoosepAlviste/nvim-ts-context-commentstring',
          after = 'nvim-treesitter'
        }

        -- Multiple cursor
        use {
          'terryma/vim-multiple-cursors'
        }

        -- -- NvimTree
        -- use {
        --   'kyazdani42/nvim-tree.lua',
        --   cmd = { 'NvimTreeToggle', 'NvimTreeFocus' },
        --   requires = {
        --     'kyazdani42/nvim-web-devicons', -- optional, for file icon
        --   },
        --   config = function ()
        --       require('user.nvim-tree').config()
        --   end,
        -- }
        --
        use {
          "nvim-neo-tree/neo-tree.nvim",
          module = "neo-tree",
          cmd = "Neotree",
          requires = "MunifTanjim/nui.nvim",
          config = function()
            require("user.neo-tree").config()
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

        -- Git integration
        use {
          'tpope/vim-fugitive',
        }

        -- Autoclose tags
        use {
          'windwp/nvim-ts-autotag',
          after = 'nvim-treesitter'
        }

        -- Fixed cursor animation
        use {
          "antoinemadec/FixCursorHold.nvim",
          config = function()
              vim.g.cursorhold_updatetime = 100
          end
        }

        -- Smooth scrolling
        use {
          "karb94/neoscroll.nvim",
          config = function()
            require("user.neoscroll").config()
          end,
        }

        -- Line guides
        -- use {
        --   "lukas-reineke/indent-blankline.nvim",
        --   config = function ()
        --       require("user.indent-line").config()
        --   end
        -- }
        --
        
        -- Vim prettier
        use {
          'jose-elias-alvarez/null-ls.nvim',
          'MunifTanjim/prettier.nvim',
          config = function()
            require("user.prettier").config()
          end
        }

        use {
          'neoclide/vim-jsx-improve',
          'yuezk/vim-js',
          'maxmellon/vim-jsx-pretty',
        }

        -- Indentation detection
        -- use {
        --   "Darazaki/indent-o-matic",
        --   config = function()
        --       require("user.indent-o-matic").config()
        --   end
        -- }
        if PACKER_BOOTSTRAP then
            require("packer").sync()
        end
    end
)
