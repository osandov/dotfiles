" Omar Sandoval's .vimrc

" Use Vim settings, rather than Vi settings
set nocompatible

" allow backspacing over everything in insert mode
set backspace=indent,eol,start

set backup		" keep a backup file
set history=1000	" keep 1000 lines of command line history
set tabpagemax=50       " we can afford more than 10 tabs
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

" Sane tabs
set smarttab
set shiftround
set nojoinspaces

" Wrap at 79 characters
set textwidth=79

" Leader
nnoremap \ ,
let mapleader = ","

" Write
noremap <Leader>m :w<CR>

" Use jk to exit from insert mode
imap jk <Esc>

" Map Command-Line mode navigation to arrows keys so we can have filtering
cnoremap <C-P> <Up>
cnoremap <C-N> <Down>

filetype plugin indent on

" Avoid annoying delay in terminal
set ttimeoutlen=50

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
noremap <Leader>km :mksession! ~/.vim/tmp/session<CR>
noremap <Leader>ks :source ~/.vim/tmp/session<CR>

" Toggle relative and absolute numbering
function! g:ToggleNuMode()
    if &rnu
        set nornu
    else
        set rnu
    endif
endfunc

noremap <C-L> :call g:ToggleNuMode()<CR>

nnoremap <C-S> gUiw
vnoremap <C-S> gU
inoremap <C-S> <Esc>gUiwea
inoremap <C-Y> <Esc>I#include <<Esc>A>
nnoremap <F3> diwi#ifndef <Esc>po#define <Esc>p3a<CR><Esc>o#endif /* <Esc>pa */<Esc>2k
inoremap <F3> <Esc>diwi#ifndef <Esc>po#define <Esc>p3a<CR><Esc>o#endif /* <Esc>pa */<Esc>2ki

"""""""""" Plugins

execute pathogen#infect()

" Delimit comments with spaces
let g:NERDSpaceDelims = 1

"""""""""" Appearance

" Solarized is pretty
set background=dark
colorscheme solarized

set cursorline
" set list
" set listchars=eol:¬,extends:»,tab:▸\ ,trail:›

" XTerm-specific stuff
let s:xtermMatch = matchlist($XTERM_VERSION, 'XTerm(\(\d\+\))')
if !has("gui_running") && len(s:xtermMatch) > 0
    " Change cursor in insert mode like a GVim weenie
    let s:xtermVersion = s:xtermMatch[1]
    if s:xtermVersion >= 282
        let &t_SI .= "\<Esc>[6 q"
    else
        let &t_SI .= "\<Esc>[4 q"
    endif
    let &t_EI .= "\<Esc>[2 q"
    " 0 or 1 -> blinking block
    " 2 -> solid block
    " 3 -> blinking underscore
    " 4 -> solid underscore
    " Recent versions of xterm (282 or above) also support
    " 5 -> blinking vertical bar
    " 6 -> solid vertical bar

    " Ugh, Meta-Alt-Escape crap
    exec "set <M-b>=\eb"
    exec "set <M-f>=\ef"
endif
