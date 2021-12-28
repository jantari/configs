" Neovim configuration file

set number
set background=dark

" Turn off backup and swapfiles
set nobackup
set nowritebackup
set noswapfile

" 4 spaces instead of Tab
set expandtab
set shiftwidth=4
set tabstop=4

" Ignore case when searching
set ignorecase

" Copy to system clipboard with Ctrl-C
vnoremap <C-c> "+y

" Set to auto read when a file is changed from the outside
set autoread

" Keep 4 lines on screen ahead of the cursor
set scrolloff=5

" Show matching bracket when cursor is hovering one
set showmatch

" Set indentation to 2 spaces for YAML
autocmd FileType yaml setlocal shiftwidth=2 tabstop=2

" When we create a NEW .ps1 file with vim, add a BOM by default
autocmd FileType ps1 setlocal bomb

" Enable 24-bit TrueColor
if (empty($TMUX))
  if (has("termguicolors"))
    set termguicolors
  endif
endif

" Load vim-plug plugins
call plug#begin()
Plug 'sheerun/vim-polyglot'
Plug 'ryanoasis/vim-devicons'
Plug 'kyazdani42/nvim-web-devicons'
Plug 'kyazdani42/nvim-tree.lua'
Plug 'lukas-reineke/indent-blankline.nvim'
Plug 'itchyny/lightline.vim'
Plug 'tomasiser/vim-code-dark'
Plug 'nvim-lua/plenary.nvim'
Plug 'lewis6991/gitsigns.nvim', {'branch': 'main'}
Plug 'rhysd/git-messenger.vim'

" LSP stuff:
Plug 'neovim/nvim-lspconfig'
Plug 'williamboman/nvim-lsp-installer'

" Completion stuff:
Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'L3MON4D3/LuaSnip'
Plug 'saadparwaiz1/cmp_luasnip'
call plug#end()

colorscheme codedark

" Highlight current line
set cursorline
highlight CursorLine cterm=none
highlight CursorLineNR cterm=inverse gui=inverse

" No fat background highlight on split divider
highlight VertSplit cterm=NONE guifg=Text

" Override parts of the theme. Particularly the background
" so that the terminals background is seen through instead.
highlight Normal ctermbg=None guibg=None
highlight SignColumn guibg=None
highlight LineNR guibg=None guifg=#8c8c8c
highlight! def link Comment NonText
highlight EndOfBuffer guibg=None
highlight! Directory guibg=None

" Render invisible characters
set list
set listchars=tab:→\ ,nbsp:␣,trail:·,eol:↲
highlight NonText ctermfg=0 guibg=None

" Lightline configurations
set noshowmode
let g:lightline = {
  \ 'colorscheme': 'one',
  \ }

" Configure Indent-Guide
let g:indentLine_char = '▏'
let g:indent_blankline_show_first_indent_level = v:false

" Gitsigns configuration
:lua require('gitsigns').setup{
    \ current_line_blame = true,
    \ use_decoration_api = true,
    \ signs = {
    \   add = { text ='+' },
    \   delete = { text = '-' },
    \   change = { text = '±' },
    \ },
    \ numhl = false,
    \ linehl = false,
    \ }

" Show git popup / history with Ctrl + g
nnoremap <C-g> :GitMessenger<CR>

" Open/Close NvimTree with Ctrl + B
map <C-b> :NvimTreeToggle<CR>

" Completion setup
set completeopt=menu,menuone,noselect

lua <<EOF
  local luasnip = require 'luasnip'
  local cmp = require'cmp'

  local on_attach = function(_, bufnr)
    vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

    local opts = { noremap = true, silent = true }
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
    -- vim.api.nvim_buf_set_keymap(bufnr, 'v', '<leader>ca', '<cmd>lua vim.lsp.buf.range_code_action()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>so', [[<cmd>lua require('telescope.builtin').lsp_document_symbols()<CR>]], opts)
    -- vim.cmd [[ command! Format execute 'lua vim.lsp.buf.formatting()' ]]
  end

  cmp.setup{
    snippet = {
      expand = function(args)
        require('luasnip').lsp_expand(args.body)
      end,
    },
    sources = {
      { name = 'nvim_lsp' },
      { name = 'luasnip' },
      { name = 'buffer' },
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
  }

  -- Setup lspconfig.
  local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())

  require('lspconfig').powershell_es.setup{
    filetypes = {"ps1", "psm1", "psd1"},
    on_attach = on_attach,
    capabilities = capabilities,
    bundle_path = '~/AppData/Local/nvim-data/lsp_servers/powershell_es',
  }
EOF

" Nvimtree configuration
let g:nvim_tree_git_hl = 1
let g:nvim_tree_highlight_opened_files = 1
let g:nvim_tree_indent_markers = 1

:lua require('nvim-tree').setup{
  \   auto_close = true,
  \   update_focused_file = {
  \     enable = true
  \   }
  \ }

