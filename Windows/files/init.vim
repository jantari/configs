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
set scrolloff=4

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
Plug 'nvim-lua/completion-nvim'
Plug 'steelsojka/completion-buffers'
Plug 'tomasiser/vim-code-dark'
Plug 'nvim-lua/plenary.nvim'
Plug 'lewis6991/gitsigns.nvim', {'branch': 'main'}
Plug 'rhysd/git-messenger.vim'
call plug#end()

colorscheme codedark

" Highlight current line
set cursorline
highlight CursorLine cterm=none
highlight CursorLineNR cterm=inverse gui=inverse

" No fat background highlight on split divider
highlight VertSplit cterm=inverse guifg=Text

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
highlight NonText guibg=None

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

autocmd BufEnter * lua require'completion'.on_attach()

" Set completeopt to have a better completion experience
set completeopt=menuone,noinsert,noselect

" Avoid showing message extra message when using completion
set shortmess+=c

let g:completion_chain_complete_list = [
    \{'complete_items': ['lsp', 'snippet', 'buffer']},
    \{'mode': '<c-p>'},
    \{'mode': '<c-n>'}
\]

" Nvimtree configuration
let g:nvim_tree_auto_close = 1
let g:nvim_tree_git_hl = 1
let g:nvim_tree_highlight_opened_files = 1

