" Omar Sandoval's .vimrc

" Use Vim settings, rather than Vi settings
set nocompatible

" allow backspacing over everything in insert mode
set backspace=indent,eol,start

set backup		" keep a backup file
set history=200		" keep 200 lines of command line history
set ruler		" show the cursor position all the time
set showcmd		" display incomplete commands
set incsearch		" do incremental searching

" Don't use Ex mode, use Q for formatting
map Q gq

" CTRL-U in insert mode deletes a lot.  Use CTRL-G u to first break undo,
" so that you can undo CTRL-U after inserting a line break.
inoremap <C-U> <C-G>u<C-U>

" In many terminal emulators the mouse works just fine, thus enable it.
if has('mouse')
    set mouse=a
endif

" Switch syntax highlighting on, when the terminal has colors
" Also switch on highlighting the last used search pattern.
if &t_Co > 2 || has("gui_running")
    syntax on
    set hlsearch
endif

" Only do this part when compiled with support for autocommands.
filetype plugin indent on

" Put these in an autocmd group, so that we can delete them easily.
augroup vimrcEx
    au!

    " For all text files set 'textwidth' to 78 characters.
    autocmd FileType text setlocal textwidth=78

    " When editing a file, always jump to the last known cursor position.
    " Don't do it when the position is invalid or when inside an event handler
    " (happens when dropping a file on gvim).
    " Also don't do it when the mark is in the first line, that is the default
    " position when opening a file.
    autocmd BufReadPost *
                \ if line("'\"") > 1 && line("'\"") <= line("$") |
                \   exe "normal! g`\"" |
                \ endif

augroup END

" Convenient command to see the difference between the current buffer and the
" file it was loaded from, thus the changes you made.
" Only define it when not defined already.
if !exists(":DiffOrig")
    command DiffOrig vert new | set bt=nofile | r # | 0d_ | diffthis
                \ | wincmd p | diffthis
endif

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

filetype plugin on

" Use 4 spaces instead of the tab character for indentation
set expandtab
set shiftwidth=4
set softtabstop=4

" Backup files in another directory to avoid clutter
set backupdir=~/.vim/backup
set directory=~/.vim/tmp

" A few conveniences
set splitright splitbelow
set number      " Number lines
set spell       " Spellcheck
set autochdir   " Always cd to the current file's directory

" Leader
nnoremap \ ,
let mapleader = ","

" Swap : and ; in normal and visual modes
nnoremap ; :
nnoremap : ;
vnoremap ; :
vnoremap : ;

" Toggle search highlighting and spellcheck
nnoremap <Space> :set hls!<CR>
vnoremap <Space> :set hls!<CR>
nnoremap <S-Space> :set spell!<CR>
vnoremap <S-Space> :set spell!<CR>

" Use jk to exit from insert mode
imap jk <Esc>

" Edit .vimrc on the fly
noremap <leader>ev :split $MYVIMRC<CR>
noremap <leader>sv :source $MYVIMRC<CR>

" Map Command-Line mode navigation to arrows keys so we can have filtering
cnoremap <C-p> <Up>
cnoremap <C-n> <Down>

" Make Command-Line mode tab completion behave more like zsh
set wildmenu
set wildmode=full

" When switching buffers, switch to an existing tab if the buffer is open or
" create a new one if it is not
set switchbuf=usetab,newtab

inoremap <C-s> <Esc>gUiwea
imap <C-y> <Esc>I#include <<Esc>A>
map <F3> diwi#ifndef <Esc>po#define <Esc>p3a<CR><Esc>o#endif /* <Esc>pa */<Esc>2k

" Ctags commands
map <C-\> :tab split<CR>:exec("tag ".expand("<cword>"))<CR>
map <A-]> :vsp <CR>:exec("tag ".expand("<cword>"))<CR>

execute pathogen#infect()

" Delimit comments with spaces
let g:NERDSpaceDelims = 1
