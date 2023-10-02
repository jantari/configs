require("lazy").setup({
  --[[
  {
    'projekt0n/github-nvim-theme',
    lazy = false, -- make sure we load this during startup if it is your main colorscheme
    priority = 1000, -- make sure to load this before all the other start plugins
    config = function()
      require('github-theme').setup({
        options = {
          darken = {
            sidebars = {
              enabled = true,
            }
          },
          styles = {
            comments = 'italic',
          }
        }
      })

      vim.cmd('colorscheme github_dark')
    end,
  },
  ]]--
  {
    'Mofiqul/vscode.nvim',
    lazy = false,
    priority = 1000,
    config = function()
      require('vscode').setup({
        transparent = false,
        italic_comments = true,
      })
      require('vscode').load()
    end,
  },
  { 'sheerun/vim-polyglot', lazy = true },
  { "nvim-tree/nvim-web-devicons", lazy = true },
  {
    'lewis6991/gitsigns.nvim',
    lazy = true,
    branch = 'main',
    config = function()
      require('gitsigns').setup{
        current_line_blame = true,
        signs = {
          add = { hl = "DiffAdd", text = "+", numhl = "GitSignsAddNr" },
          delete = { hl = "DiffDelete", text = "-", numhl = "GitSignsDeleteNr" },
          change = { hl = "DiffChange", text = "±", numhl = "GitSignsChangeNr" },
        },
        numhl = false,
        linehl = false,
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns

          local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
          end

          map('n', '<leader>hr', gs.reset_hunk)
          map('v', '<leader>hr', function() gs.reset_hunk {vim.fn.line('.'), vim.fn.line('v')} end)
          map('n', '<leader>hp', gs.preview_hunk)
        end
      }
    end
  },
  {
    'rhysd/git-messenger.vim',
  },
  {
    'nvim-lualine/lualine.nvim',
    lazy = false,
    dependencies = {
      'nvim-tree/nvim-web-devicons', -- OPTIONAL
    },
    config = function()
      require('lualine').setup{
        options = {
          --theme = 'vscode',
          theme = 'auto',
          section_separators = { left = '', right = '' },
          component_separators = { left = '', right = '' },
        },
        sections = {
          lualine_x = {
            'encoding',
            {
              'fileformat',
              icons_enabled = true,
              symbols = {
                unix = 'LF',
                dos = 'CRLF',
                mac = 'CR',
              },
            },
            'filetype',
          }
        }
      }
    end
  },
  { 'nvim-treesitter/nvim-treesitter', build = ':TSUpdate'},
  {
    'lukas-reineke/indent-blankline.nvim',
    event = "VimEnter",
    config = function()
      require('ibl').setup{
        indent = {
          char = '▏',
        },
        scope = { enabled = false },
        exclude = {
          filetypes = {'markdown'},
        },
      }

      local hooks = require "ibl.hooks"
      hooks.register(hooks.type.WHITESPACE, hooks.builtin.hide_first_space_indent_level)
      hooks.register(hooks.type.WHITESPACE, hooks.builtin.hide_first_tab_indent_level)
    end,
  },
  {
    'nvim-tree/nvim-tree.lua',
    -- 'kyazdani42/nvim-tree.lua',
    lazy = false,
    config = function()
      -- Nvimtree configuration
      require('nvim-tree').setup{
        filters = {
          custom = { '.git', 'node_modules', '.cache' },
        },
        update_focused_file = {
          enable = true
        },
        git = {
          enable = true,
          ignore = true,
          timeout = 400,
        },
        view = {
          width = 42
        },
        renderer = {
          highlight_git = true,
          indent_markers = {
            enable = false,
          },
        },
      }

      -- Open/Close NvimTree with Ctrl + B
      vim.keymap.set({'n', 'i', 'v'}, '<C-b>', ':NvimTreeToggle<CR>')
    end
  },
  {
    'romgrk/barbar.nvim',
    dependencies = {
      'lewis6991/gitsigns.nvim', -- OPTIONAL: for git status
      'nvim-tree/nvim-web-devicons', -- OPTIONAL: for file icons
    },
    init = function() vim.g.barbar_auto_setup = false end,
    opts = {
      -- lazy.nvim will automatically call setup for you. put your options here, anything missing will use the default:
      -- animation = true,
      -- insert_at_start = true,
      -- …etc.
      icons = {
        inactive = {separator = {left = '▏', right = ''}},
        separator = {left = '▏', right = ''},
        separator_at_end = false,
      },
      sidebar_filetypes = {
        NvimTree = true,
      },
    },
    version = '^1.0.0', -- optional: only update when a new 1.x version is released
  },
  -- LSP Stuff
  { 'williamboman/mason.nvim', lazy = true },
  { 'williamboman/mason-lspconfig.nvim', lazy = true },
  { 'neovim/nvim-lspconfig', lazy = true },
  -- Completion stuff
  { 'hrsh7th/nvim-cmp', lazy = true },
  { 'hrsh7th/cmp-nvim-lsp', lazy = true },
  { 'hrsh7th/cmp-nvim-lsp-signature-help', lazy = true },
  { 'hrsh7th/cmp-buffer', lazy = true },
  -- nvim-cmp REQUIRES a snippet plugin
  { 'L3MON4D3/LuaSnip', lazy = true },
  { 'saadparwaiz1/cmp_luasnip', lazy = true },
})
