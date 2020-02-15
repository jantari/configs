" Neovim configuration file

set number

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

" Keep 4 lines on screen ahead of the cursor 
set scrolloff=4

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
Plug 'taigacute/spaceline.vim'
call plug#end()
