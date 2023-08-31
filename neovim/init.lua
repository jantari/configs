-- disable netrw at the very start of your init.lua (strongly advised)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.wo.number = true
vim.opt.background = 'dark'

-- Turn off backup and swapfiles
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false

-- 4 spaces instead of Tab
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4

-- 2 spaces for lua and yaml files
vim.api.nvim_create_autocmd("FileType", {
  pattern = {"lua", "yaml"},
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
  end
})

vim.wo.cursorline = true
vim.opt.ignorecase = true

vim.opt.termguicolors = true

-- Keep 5 lines on screen ahead of the cursor
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

-- Highlight current line
vim.api.nvim_set_hl(0, 'CursorLine', {})
vim.api.nvim_set_hl(0, 'CursorLineNr', {cterm=inverse, fg=inverse})
--vim.api.nvim_set_hl(0, 'NvimTreeNormal', {link = 'StatusLineNC'})

require('plugins')

-- Render invisible characters
vim.opt.list = true
vim.opt.listchars = {tab='→ ', nbsp='␣', trail='·', eol='↲'}

-- Do not use any text character in vertical split separator
vim.opt.fillchars:append("vert: ")

-- lualine configurations
vim.o.showmode = false

-- Override parts of the vscode theme
-- No fat background highlight on split divider
--vim.api.nvim_set_hl(0, 'VertSplit', {ctermbg='NONE', bg='NONE'})
--vim.api.nvim_set_hl(0, 'Comment', {link = 'NonText'})

require'nvim-treesitter.configs'.setup {
  ensure_installed = { "go", "python", "dockerfile" },
  sync_install = false,
  auto_install = false,

  highlight = {
    enable = true,
    use_languagetree = true,
    disable = { "lua" },
  }
}

-- Configure Indent-Guide
require("indent_blankline").setup {
  -- for example, context is off by default, use this to turn it on
  show_first_indent_level = false,
  show_current_context = true,
  --show_current_context_start = true,
  char = '▏',
  filetype_exclude = {
    'markdown'
  },
}

-- nvim-cmp supports additional completion capabilities, so broadcast that to servers
local capabilities = require('cmp_nvim_lsp').default_capabilities()

require("mason").setup{}
require("mason-lspconfig").setup{}

require('lspconfig').gopls.setup{
  capabilities = capabilities,
}

require('lspconfig').powershell_es.setup{
  filetypes = {"ps1", "psm1", "psd1"},
  bundle_path = '~/AppData/Local/nvim-data/lsp_servers/powershell_es',
  capabilities = capabilities,
}


-- Completion setup
vim.o.completeopt = 'menu,menuone,noselect'

-- Set up nvim-cmp.
local kind_icons = {
  Text = "",
  Method = "",
  Function = "",
  Constructor = "",
  Field = "",
  --Variable = "",
  --Variable = "",
  Variable = "",
  Class = "ﴯ",
  Interface = "",
  Module = "",
  Property = "ﰠ",
  Unit = "",
  Value = "",
  Enum = "",
  Keyword = "",
  Snippet = "",
  Color = "",
  File = "",
  Reference = "",
  Folder = "",
  EnumMember = "",
  Constant = "",
  Struct = "",
  Event = "",
  Operator = "",
  TypeParameter = ""
}

local luasnip = require 'luasnip'
local cmp = require'cmp'

cmp.setup({
  snippet = {
    -- REQUIRED - you must specify a snippet engine
    expand = function(args)
      require('luasnip').lsp_expand(args.body)
    end,
  },
  formatting = {
    format = function(entry, vim_item)
      -- Kind icons
      vim_item.kind = string.format('%s', kind_icons[vim_item.kind]) -- only showthe icon, not the kind text
      -- Source
      vim_item.menu = ({
        buffer = "📜",
        nvim_lsp = "💡",
        luasnip = "[LuaSnip]",
        nvim_lua = "[Lua]",
        latex_symbols = "[LaTeX]",
      })[entry.source.name]
      return vim_item
    end
  },
  sources = {
    { name = 'nvim_lsp' },
    { name = 'nvim_lsp_signature_help' },
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

-- Unbind default Shift + Up/Down -> PgUp / PgDown
vim.keymap.set({'n', 'i', 'v'}, '<S-Up>', '<Up>')
vim.keymap.set({'n', 'i', 'v'}, '<S-Down>', '<Down>')

-- Yank to system clipboard with Ctrl-C
vim.keymap.set({'v'}, '<C-c>', '"+y')

-- LSP keymappings
-- Show hover info
vim.keymap.set({'n'}, 'K', '<cmd>lua vim.lsp.buf.hover()<cr>')
-- Go to definition
vim.keymap.set({'n'}, 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>')
-- Show all references
vim.keymap.set({'n'}, 'gr', '<cmd>lua vim.lsp.buf.references()<cr>')

vim.g.git_messenger_always_into_popup = true
