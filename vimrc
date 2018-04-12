" Omar Sandoval's .vimrc

"""""""""" Settings

" Miscellaneous settings for the 21st century
set nocompatible         " no Vi-compatibility
set backspace=indent,eol,start " more powerful backspace
set history=1000         " keep 1000 lines of command line history
set showcmd              " display incomplete commands
set tabpagemax=50        " we can afford more than 10 tabs
set ttimeoutlen=50       " avoid annoying delay in terminal
if has('mouse')
    set mouse=a
    set ttymouse=sgr
endif

" Avoid clutter
set nobackup             " don't keep backup files
set directory=~/.vim/tmp " put swap files somewhere else
if !isdirectory(&directory)
    call mkdir(&directory, "p")
endif

" Behavior
set completeopt-=preview " no annoying completion preview window
set incsearch            " do incremental searching
set nojoinspaces         " one space after periods when joining
set splitbelow           " personal preference
set splitright
set wildmenu             " zsh-ish command-line tab completion
set wildmode=list:longest,list:full

" Appearance
set cursorline           " indicate current line
set hlsearch             " highlight search matches
set number               " number lines
set relativenumber       " relative line numbering
set ruler                " show the cursor position all the time
if !has("gui_running")
    " Change cursor in insert mode and replace mode like a GVim weenie
    let &t_SI .= "\<Esc>[6 q"
    let &t_EI .= "\<Esc>[2 q"
    if exists("&t_SR")
        let &t_SR .= "\<Esc>[4 q"
    endif
    " 0 or 1 -> blinking block
    " 2 -> solid block
    " 3 -> blinking underscore
    " 4 -> solid underscore
    " Recent versions of xterm (282 or above) and urxvt also support
    " 5 -> blinking vertical bar
    " 6 -> solid vertical bar

    let s:xtermMatch = matchlist($XTERM_VERSION, 'XTerm(\(\d\+\))')
    if len(s:xtermMatch) > 0
        " Ugh, Meta-Alt-Escape crap
        exec "set <M-b>=\eb"
        exec "set <M-f>=\ef"
    endif
endif
syntax on
set background=light
colorscheme minimal

" Autocmds and filetype-specific stuff
augroup vimrc
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

    " Resize splits when the terminal is resized
    autocmd VimResized * wincmd =

    " I don't write Modula
    autocmd BufRead,BufNewFile *.md set filetype=markdown

    " I do write AsciiDoc, though
    autocmd BufRead,BufNewFile *.adoc set filetype=asciidoc

    " Close enough for Coccinelle
    autocmd BufRead,BufNewFile *.cocci set filetype=diff
augroup END

" Use LaTeX instead of plain TeX for .tex files
let g:tex_flavor = 'latex'

" Use C syntax for *.h files, not C++
let g:c_syntax_for_h = 1

" Highlight bad spacing
let g:c_space_errors = 1
let g:python_space_error_highlight=1

"""""""""" Mappings

" Map Command-Line mode navigation to arrows keys so we can have filtering
cnoremap <C-P> <Up>
cnoremap <C-N> <Down>

" Move quickly between tabs
nnoremap <C-N> gt
nnoremap <C-P> gT

" Clear search highlighting
nnoremap <Space> :nohl<CR>
vnoremap <Space> :nohl<CR>

" CTRL-U in insert mode deletes a lot. Use CTRL-G u to first break undo, so
" that you can undo CTRL-U after inserting a line break.
inoremap <C-U> <C-G>u<C-U>

" Open tag in a new tab
nnoremap <silent><C-\><C-]> <C-w><C-]><C-w>T

" Leader mappings
nnoremap \ ,
let mapleader = ","

" Convenient save
noremap <Leader>m :up<CR>

" Move between windows
noremap <Leader>w <C-W>w

" Splits
noremap <Leader>s <C-W>s
noremap <Leader>v <C-W>v
noremap <Leader>t <C-W>s<C-W>T

" Start a search for a whole word
noremap <Leader>/ /\<\><Left><Left>

" Manual autochdir
noremap <Leader>cd :cd %:p:h<CR>

" Quick and dirty sessions
noremap <Leader>km :mksession! ~/.vim/tmp/session<CR>
noremap <Leader>ks :source ~/.vim/tmp/session<CR>

" Toggle relative and absolute numbering
noremap <Leader>ln :set rnu!<CR>

cnoremap w!! SudoWrite

"""""""""" Plugins

filetype off
if isdirectory($HOME . "/.vim/bundle/Vundle.vim")
    set rtp+=~/.vim/bundle/Vundle.vim
    call vundle#begin()

    Plugin 'VundleVim/Vundle.vim'

    Plugin 'chrisbra/SudoEdit.vim'
    Plugin 'ervandew/supertab'
    Plugin 'rking/ag.vim'
    Plugin 'scrooloose/nerdcommenter'
    Plugin 'tpope/vim-fugitive'
    Plugin 'tpope/vim-repeat'
    Plugin 'tpope/vim-rsi'
    Plugin 'tpope/vim-vinegar'
    Plugin 'Vimjas/vim-python-pep8-indent'

    call vundle#end()
endif
filetype plugin indent on

" Delimit comments with spaces
let g:NERDSpaceDelims = 1
" Workaround stupid extra space hardcoded for Python
let g:NERDCustomDelimiters = {'python': {'left': '#'}, 'pyrex': {'left': '#'}}

" Also autocomplete C preprocessor macros
let g:clang_complete_macros = 1

if executable("goimports")
    let g:gofmt_command="goimports"
endif

" SuperTab scroll down
let g:SuperTabDefaultCompletionType = "<C-N>"

" Plugin autocmds
augroup vimrcPlugin
    au!

    " Use omnicomplete and keyword completion for supertab
    autocmd FileType *
                \ if &omnifunc != '' |
                \   call SuperTabChain(&omnifunc, "<C-N>") |
                \   call SuperTabSetDefaultCompletionType("<C-X><C-U>") |
                \ endif

    " Override the vim-vinegar settings for the following
    autocmd FileType * let g:netrw_sort_sequence=''
    " Ignore
    " - ".*" but not "./" or "../"
    " - "*.o" and "*.dwo"
    " - "*.pyc" and "__pycache__"
    autocmd FileType * let g:netrw_list_hide='^\.\([^./]\|\.[^/]\),\.o$,\.dwo$,\.pyc$,^__pycache__$'
augroup END
