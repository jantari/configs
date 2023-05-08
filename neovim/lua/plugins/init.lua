--

require("lazy").setup({
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
      }
    end,
  },
  {
    'rhysd/git-messenger.vim',
  },
  { 'nvim-lualine/lualine.nvim', lazy = true },
  { 'nvim-treesitter/nvim-treesitter', build = ':TSUpdate'},
  'lukas-reineke/indent-blankline.nvim',
  { 'kyazdani42/nvim-tree.lua', lazy = true },
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
