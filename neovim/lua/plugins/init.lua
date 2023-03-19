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
        linehl = true,
      }
    end,
  },
  { 'nvim-lualine/lualine.nvim', lazy = true },
  { 'nvim-treesitter/nvim-treesitter', build = ':TSUpdate'},
  'lukas-reineke/indent-blankline.nvim',
  { 'kyazdani42/nvim-tree.lua', lazy = true },
  {
    'akinsho/bufferline.nvim',
    lazy = false,
    version = "3.x",
    dependencies = { 'nvim-tree/nvim-web-devicons', },
    config = function()
      require("bufferline").setup{
        options = {
          tab_size = 22,
          offsets = {
            {
              filetype = "NvimTree",
              separator = " ", -- use a "true" to enable the default, or set your own character
            }
          },
          diagnostics = "nvim_lsp",
          separator_style = {"", ""},
        },
        highlights = {
          background = {
              fg = { attribute = "fg", highlight = "Normal" },
              bg = { attribute = "bg", highlight = "StatusLine" },
          },
          buffer_visible = {
              fg = { attribute = "fg", highlight = "Normal" },
              bg = { attribute = "bg", highlight = "Normal" },
          },
          buffer_selected = {
              fg = { attribute = "fg", highlight = "Normal" },
              bg = { attribute = "bg", highlight = "Normal" },
              bold = true,
              italic = false,
          },
          duplicate = {
            fg = { attribute = "fg", highlight = "Normal" },
            bg = { attribute = "bg", highlight = "StatusLine" },
            italic = false,
          },
          duplicate_selected = {
            fg = { attribute = "fg", highlight = "Normal" },
            bg = { attribute = "bg", highlight = "Normal" },
            bold = false,
            italic = false,
          },
          duplicate_visible = {
            fg = { attribute = "fg", highlight = "Normal" },
            bg = { attribute = "bg", highlight = "Normal" },
            italic = false,
          },
          offset_separator = {
            fg = { attribute = "fg", highlight = "Normal" },
            bg = { attribute = "bg", highlight = "Normal" },
          },
          close_button = {
              fg = { attribute = "fg", highlight = "Normal" },
              bg = { attribute = "bg", highlight = "StatusLine" },
          },
          close_button_selected = {
              fg = { attribute = "fg", highlight = "Normal" },
              bg = { attribute = "bg", highlight = "Normal" },
          },
          close_button_visible = {
              fg = { attribute = "fg", highlight = "Normal" },
              bg = { attribute = "bg", highlight = "Normal" },
          },
        },
      }
    end
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
