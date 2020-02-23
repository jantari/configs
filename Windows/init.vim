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

" Set to auto read when a file is changed from the outside
set autoread

" Keep 4 lines on screen ahead of the cursor 
set scrolloff=4

" Show matching bracket when cursor is hovering one
set showmatch

" Highlight current line
set cursorline
highlight CursorLine cterm=none
highlight CursorLineNR cterm=inverse

" Render invisible characters
set list
set listchars=tab:→\ ,nbsp:␣,space:·,trail:-,eol:↲
highlight NonText ctermfg=6

" Load vim-plug plugins
call plug#begin()
Plug 'PProvost/vim-ps1'
Plug 'ryanoasis/vim-devicons'
Plug 'preservim/nerdtree'
Plug 'pearofducks/ansible-vim'
Plug 'taigacute/spaceline.vim'
call plug#end()

" Open NERDTree with Ctrl + B
map <C-b> :NERDTreeToggle<CR>

" Show hidden dotfiles by default in NERDTree
let NERDTreeShowHidden=1

" Close vim if the only window left open is NERDTree
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

