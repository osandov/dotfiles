" Omar Sandoval's .vimrc

" Use Vim settings, rather than Vi settings
set nocompatible

" allow backspacing over everything in insert mode
set backspace=indent,eol,start

set backup		" keep a backup file
set history=50		" keep 50 lines of command line history
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
if has("autocmd")

    " Enable file type detection.
    " Use the default filetype settings, so that mail gets 'tw' set to 72,
    " 'cindent' is on in C files, etc.
    " Also load indent files, to automatically do language-dependent indenting.
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

else

    set autoindent		" always set autoindenting on

endif " has("autocmd")

" Convenient command to see the difference between the current buffer and the
" file it was loaded from, thus the changes you made.
" Only define it when not defined already.
if !exists(":DiffOrig")
    command DiffOrig vert new | set bt=nofile | r # | 0d_ | diffthis
                \ | wincmd p | diffthis
endif

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Use 4 spaces instead of the tab character for indentation
set expandtab
set shiftwidth=4
set softtabstop=4

" Backup files in another directory to avoid clutter
set backupdir=~/.vim/backup
set directory=~/.vim/tmp

" A few conveniences
set number      " Number lines
set autochdir   " Always cd to the current file's directory
nnoremap \ ,
let mapleader = ","
" set textwidth=80 " Limit lines to 80 characters

" Swap : and ; in normal and visual modes
nnoremap ; :
nnoremap : ;
vnoremap ; :
vnoremap : ;

" Use jk to exit from insert mode
imap jk <Esc>

" Enable C++11 syntax highlighting
" autocmd BufNewFile,BufRead *.cpp set syntax=cpp11

" Ctags commands
map <C-\> :tab split<CR>:exec("tag ".expand("<cword>"))<CR>
map <A-]> :vsp <CR>:exec("tag ".expand("<cword>"))<CR>

" Function macros
map <F2> I#include <Esc>j
map <F3> diwi#ifndef <Esc>po#define <Esc>p3a<CR><Esc>o#endif /* <Esc>pa */<Esc>2k

execute pathogen#infect()

" Delimit comments with spaces
execute 'let g:NERDSpaceDelims = 1'

" When switching buffers, switch to an existing tab if the buffer is open or
" create a new one if it is not
set switchbuf=usetab,newtab

" Additional plugins:
"   Pathogen
"   Solarized
"   NERD Commenter
"   cScope
"   Ctags
"   Tag List Plugin
"   Code completion

" Put the following lines in .Xmodmap to map Caps Lock to <Esc>
" clear lock
" keycode 0x42 = Escape
