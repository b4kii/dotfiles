-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function()
    -- Packer can manage itself
    use {
        'wbthomason/packer.nvim'
    }

    -- Theme
    use {
        'Shatur/neovim-ayu'
    }

    -- Bufferline
    use {
        'akinsho/bufferline.nvim',
        require('bufferline').setup{}
    }

    -- Statusline
    use {
        'nvim-lualine/lualine.nvim',
        require('lualine').setup {
            options = {theme = 'ayu'},
        }
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
        -- require('nvim-autopairs').setup{
        -- }
        require('configs.autopairs').config()
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
        cmd = { "NvimTreeToggle", "NvimTreeFocus" },
        requires = {
          'kyazdani42/nvim-web-devicons', -- optional, for file icon
        },
        require('configs.nvim-tree').config()
        -- require('nvim-tree').setup{}

    }

    -- Cmp plugins
    use {
        'hrsh7th/nvim-cmp',
        'hrsh7th/cmp-buffer',
        'hrsh7th/cmp-path',
        'hrsh7th/cmp-cmdline',
        'saadparwaiz1/cmp_luasnip'
    }

    -- Snippets
    use {
        'L3MON4D3/LuaSnip',
        'rafamadriz/friendly-snippets'
    }

    -- Parenthesis highlighting
    use { 
        'p00f/nvim-ts-rainbow'
    }

    -- Syntax highlighting
    use { 
        'nvim-treesitter/nvim-treesitter'
    }

    -- LSP manager
    use { 
        'williamboman/nvim-lsp-installer'
    }

    -- Built in LSP
    use { 
        'neovim/nvim-lspconfig'
    }

end)
