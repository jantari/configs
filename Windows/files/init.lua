
-- disable netrw at the very start of your init.lua (strongly advised)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.wo.number = true
vim.opt.background = 'dark'

-- Turn off backup and swapfiles
vim.o.nobackup = true
vim.o.nowritebackup = true
vim.o.noswapfile = true

-- 4 spaces instead of Tab
vim.o.expandtab = true
vim.o.shiftwidth = 4
vim.o.tabstop = 4

vim.wo.cursorline = true
vim.opt.ignorecase = true

vim.opt.termguicolors = true

-- Keep 4 lines on screen ahead of the cursor
vim.o.scrolloff = 5

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--single-branch",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
end
vim.opt.runtimepath:prepend(lazypath)

require("lazy").setup({
  'sheerun/vim-polyglot',
  { 'lewis6991/gitsigns.nvim', branch = 'main'},
  'nvim-lualine/lualine.nvim',
  'tomasiser/vim-code-dark',
  'lukas-reineke/indent-blankline.nvim',
  'kyazdani42/nvim-tree.lua',
  -- LSP Stuff
  'williamboman/mason.nvim',
  'williamboman/mason-lspconfig.nvim',
  'neovim/nvim-lspconfig',
  -- Completion stuff
  'hrsh7th/nvim-cmp',
  'hrsh7th/cmp-nvim-lsp',
  'hrsh7th/cmp-buffer',
  -- nvim-cmp REQUIRES a snippet plugin
  'L3MON4D3/LuaSnip',
  'saadparwaiz1/cmp_luasnip',
})

vim.cmd 'colorscheme codedark'

-- Highlight current line
vim.api.nvim_set_hl(0, 'CursorLine', {})
vim.api.nvim_set_hl(0, 'CursorLineNr', {cterm=inverse, fg=inverse})

-- Render invisible characters
vim.opt.list = true
vim.opt.listchars = {tab='→ ', nbsp='␣', trail='·', eol='↲'}
--vim.api.nvim_set_hl(0, 'NonText', {fg = 'black', bg='NONE'})
vim.cmd 'highlight NonText ctermfg=0 guibg=None'

-- lualine configurations
vim.o.showmode = false
require('lualine').setup{
  options = {
    theme = 'onedark',
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

-- No fat background highlight on split divider
vim.api.nvim_set_hl(0, 'VertSplit', {ctermbg='NONE', bg='NONE'})

-- Override parts of the theme. Particularly the background
-- so that the terminals background is seen through instead.
vim.api.nvim_set_hl(0, 'Normal', {ctermbg='NONE', bg='NONE'})
vim.api.nvim_set_hl(0, 'LineNR', {bg='NONE', fg="#8c8c8c"})

vim.api.nvim_set_hl(0, 'Comment', {link = 'NonText'})
vim.api.nvim_set_hl(0, 'EndOfBuffer', {bg='NONE'})
vim.api.nvim_set_hl(0, 'String', {fg = 'NONE'})

-- Configure Indent-Guide
require("indent_blankline").setup {
    -- for example, context is off by default, use this to turn it on
    show_first_indent_level = false,
    --show_current_context = true,
    --show_current_context_start = true,
    char = '▏',
    filetype_exclude = {
        'markdown'
    },
}

require("mason").setup{}
require("mason-lspconfig").setup{}

require('lspconfig').gopls.setup{}

require('lspconfig').powershell_es.setup{
    filetypes = {"ps1", "psm1", "psd1"},
    bundle_path = '~/AppData/Local/nvim-data/lsp_servers/powershell_es',
}

-- Open/Close NvimTree with Ctrl + B
vim.keymap.set({'n', 'i', 'v'}, '<C-b>', ':NvimTreeToggle<CR>')

-- Completion setup
vim.o.completeopt = 'menu,menuone,noselect'

-- Set up nvim-cmp.
local cmp = require'cmp'

cmp.setup({
  snippet = {
    -- REQUIRED - you must specify a snippet engine
    expand = function(args)
      require('luasnip').lsp_expand(args.body)
    end,
  },
  sources = {
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
    { name = 'buffer', keyword_length = 4, max_item_count = 10 },
  },
  preselect = cmp.PreselectMode.None,
  mapping = {
    ['<C-p>'] = cmp.mapping.select_prev_item(),
    ['<C-n>'] = cmp.mapping.select_next_item(),
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.close(),
    ['<CR>'] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    },
    ['<Tab>'] = function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end,
    ['<S-Tab>'] = function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end,
  },
})

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
    width = 32
  },
  renderer = {
    highlight_git = true,
    indent_markers = {
      enable = false,
    },
  },
}

-- Gitsigns configuration
require('gitsigns').setup{
  current_line_blame = true,
  signs = {
    add = { text ='+' },
    delete = { text = '-' },
    change = { text = '±' },
  },
  numhl = false,
  linehl = false,
}

