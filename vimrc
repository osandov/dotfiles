" Omar Sandoval's .vimrc

" Use Vim settings, rather than Vi settings
set nocompatible

" allow backspacing over everything in insert mode
set backspace=indent,eol,start

set backup		" keep a backup file
set history=500		" keep 500 lines of command line history
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

augroup vimrcEx
    au!

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

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"""""""""" Essentials

" Use 4 spaces instead of the tab character for indentation
set expandtab
set shiftwidth=4
set softtabstop=4

" Wrap at 79 characters
set textwidth=79

" Swap : and ; in normal and visual modes
nnoremap ; :
nnoremap : ;
vnoremap ; :
vnoremap : ;

" Use jk to exit from insert mode
imap jk <Esc>

" Map Command-Line mode navigation to arrows keys so we can have filtering
cnoremap <C-P> <Up>
cnoremap <C-N> <Down>

filetype plugin indent on

"""""""""" Convenient options

" Backup files in another directory to avoid clutter
set backupdir=~/.vim/backup
set directory=~/.vim/tmp

" A few conveniences
set splitright splitbelow " Personal preference
set number                " Number lines
" set spell                 " Spellcheck by default
" set autochdir             " Always cd to the current file's directory

" Make Command-Line mode tab completion behave more like zsh
set wildmenu
set wildmode=full

" When switching buffers, switch to an existing tab if the buffer is open or
" create a new one if it is not
set switchbuf=usetab,newtab

"""""""""" Useful bindings

" Toggle search highlighting
nnoremap <Space> :nohl<CR>
vnoremap <Space> :nohl<CR>

" Leader
nnoremap \ ,
let mapleader = ","

" Move between windows
noremap <Leader>w <C-W>w

" Edit .vimrc on the fly
noremap <Leader>ev :split $MYVIMRC<CR>
noremap <Leader>sv :source $MYVIMRC<CR>

" Manual autochdir
noremap <Leader>cd :cd %:p:h<CR>

" Toggle spell check
noremap <Leader>sp :set spell!<CR>

" Quick and dirty sessions
noremap <Leader>mk :mksession! ~/.vim/tmp/session<CR>
noremap <Leader>sk :source ~/.vim/tmp/session<CR>

" Open a terminal
noremap <Leader>tm :silent !xfce4-terminal &\!<CR>

" Toggle relative and absolute numbering
function! g:ToggleNuMode()
    if &rnu
        set nornu
    else
        set rnu
    endif
endfunc

noremap <C-L> <Esc>:call g:ToggleNuMode()<CR>

nnoremap <C-S> gUiw
vnoremap <C-S> gU
inoremap <C-S> <Esc>gUiwea
inoremap <C-Y> <Esc>I#include <<Esc>A>
nnoremap <F3> diwi#ifndef <Esc>po#define <Esc>p3a<CR><Esc>o#endif /* <Esc>pa */<Esc>2k
inoremap <F3> <Esc>diwi#ifndef <Esc>po#define <Esc>p3a<CR><Esc>o#endif /* <Esc>pa */<Esc>2ki

"""""""""" Plugins 

set omnifunc=syntaxcomplete#Complete

execute pathogen#infect()

" Delimit comments with spaces
let g:NERDSpaceDelims = 1
