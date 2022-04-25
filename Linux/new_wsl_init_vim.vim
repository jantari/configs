" Make :W save as superuser
if ! has('win32')
  command W w !sudo tee % > /dev/null
endif

" General
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

" Keep 4 lines on screen ahead of cursor
set scrolloff=5

" Show matching bracket when cursor is hovering one
set showmatch

" Set indentation to 2 spaces for YAML
autocmd FileType yaml setlocal shiftwidth=2 tabstop=2 expandtab

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
Plug 'preservim/nerdtree'
Plug 'Yggdroot/indentLine'
Plug 'itchyny/lightline.vim'
Plug 'tomasiser/vim-code-dark'
call plug#end()

colorscheme codedark

" Highlight current line
set cursorline
highlight CursorLine cterm=none
highlight CursorLineNR cterm=inverse gui=inverse

" No fat background highlight on split divider
highlight VertSplit cterm=NONE

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
    \ 'colorscheme': 'wombat',
    \ }

" Configure Indent-Guide
let g:indentLine_char = '▏'
" Disable conceal of backtick codeblocks inside Markdown files,
" see: https://vi.stackexchange.com/questions/7258/how-do-i-prevent-vim-from-hiding-symbols-in-markdown-and-json/19974#19974
let g:indentLine_fileTypeExclude = ['markdown']

" Open NERDTree with Ctrl + B
map <C-b> :NERDTreeToggle<CR>

" Show hidden dotfiles by default in NERDTree
let NERDTreeShowHidden=1

" Close vim if the only window left open is NERDTree
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

