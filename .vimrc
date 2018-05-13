" This will be mostly copy and pasted together,
" no claims of originality here

" Make :W save as superuser
command W w !sudo tee % > /dev/null

" 4 spaces instead of Tab
set expandtab
set shiftwidth=4
set tabstop=4

" Set to auto read when a file is changed from the outside
set autoread

" Enable line numbers by default
set number
