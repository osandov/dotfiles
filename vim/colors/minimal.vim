" Omar Sandoval's minimal colorscheme

hi clear

" Syntax
hi Comment cterm=italic ctermfg=DarkGray ctermbg=NONE gui=italic guifg=#6c6c6c guibg=NONE
hi Constant NONE
hi String ctermfg=DarkGray guifg=#6c6c6c
hi Identifier NONE
hi Statement NONE
hi PreProc NONE
hi Type NONE
hi Special NONE
hi Underlined NONE
hi Ignore NONE ctermfg=White guifg=#ffffff
hi Error NONE ctermbg=Red guibg=#ff5454
hi Todo NONE

" UI
" hi ColorColumn
" hi Conceal
hi Cursor NONE guifg=bg guibg=fg
" hi CursorIM
hi CursorLine NONE ctermbg=254 guibg=#e4e4e4
hi CursorColumn NONE ctermbg=254 guibg=#e4e4e4
hi Directory NONE ctermfg=DarkCyan guifg=#00aaaa
hi DiffAdd NONE ctermbg=LightGreen guibg=#54ff54
" hi DiffChange
hi DiffDelete NONE ctermbg=LightRed guibg=#ff5454
hi DiffText NONE cterm=bold ctermbg=Red guibg=#ff5454
hi ErrorMsg NONE ctermfg=White ctermbg=DarkRed guifg=#ffffff guibg=#aa0000
hi VertSplit NONE cterm=reverse gui=reverse
" hi Folded
" hi FoldColumn
" hi SignColumn
" hi IncSearch
hi LineNr NONE ctermfg=Black ctermbg=254 guifg=#000000 guibg=#e4e4e4
hi CursorLineNr NONE cterm=bold ctermfg=Black ctermbg=White gui=bold guifg=#545454 guibg=#ffffff
hi MatchParen NONE ctermbg=LightGray guibg=#aaaaaa
hi ModeMsg NONE cterm=bold gui=bold
hi MoreMsg NONE cterm=bold ctermfg=29 gui=bold guifg=#00875f
hi NonText NONE ctermfg=DarkBlue guifg=#0000aa
" hi Normal
hi Pmenu NONE ctermbg=195 guibg=#d7ffff
hi PmenuSel NONE ctermbg=LightGray guibg=#aaaaaa
hi PmenuSbar NONE ctermbg=LightGray guibg=#aaaaaa
hi PmenuThumb NONE ctermbg=Black guibg=#000000
hi Question NONE cterm=bold ctermfg=29 gui=bold guifg=#00875f
hi Search NONE ctermbg=Yellow guibg=#ffff54
" hi SpecialKey
" hi SpellBad
" hi SpellCap
" hi SpellLocal
" hi SpellRare
hi StatusLine NONE cterm=bold,reverse gui=bold,reverse
hi StatusLineNC NONE cterm=reverse gui=reverse
hi TabLine NONE ctermfg=Black ctermbg=LightGray guifg=#000000 guibg=#aaaaaa
hi TabLineFill NONE cterm=reverse gui=reverse
hi TabLineSel NONE cterm=bold ctermfg=Black gui=bold guifg=#000000
hi Title NONE ctermfg=DarkBlue guifg=#0000aa
hi Visual NONE ctermbg=LightGray guibg=#aaaaaa
" hi VisualNOS
hi WarningMsg NONE ctermfg=Red guifg=#ff5454
" hi WildMenu

" Filetype-specific
" Diff
" TODO: git diff index lines should be diffFile
hi diffFile NONE cterm=bold gui=bold guifg=#545454
hi diffLine NONE ctermfg=DarkCyan guifg=#00aaaa
hi diffAdded NONE ctermfg=DarkGreen guifg=#00aa00
hi diffRemoved NONE ctermfg=DarkRed guifg=#aa0000
