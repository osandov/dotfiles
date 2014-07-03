" Ignore indents caused by parentheses in FreeBSD style.
function! IgnoreParenIndent()
    let indent = cindent(v:lnum)

    if indent > 4000
        if cindent(v:lnum - 1) > 4000
            return indent(v:lnum - 1)
        else
            return indent(v:lnum - 1) + 4
        endif
    else
        return (indent)
    endif
endfun

" Follow the FreeBSD style(9).
function! Style9()
    let s:c_style = "style(9)"
    setlocal cindent
    setlocal cinoptions=(4200,u4200,+0.5s,*500,:0,t0,U4200
    setlocal indentexpr=IgnoreParenIndent()
    setlocal indentkeys=0{,0},0),:,0#,!^F,o,O,e
    setlocal noexpandtab
    setlocal shiftwidth=8
    setlocal softtabstop=0
    setlocal tabstop=8
    setlocal textwidth=80
endfun

function! StyleMine()
    let s:c_style = "Style Mine"
    setlocal cindent
    setlocal cinoptions=
    setlocal indentexpr=
    setlocal indentkeys=0{,0},:,0#,!^F,o,O,e
    setlocal expandtab
    setlocal shiftwidth=4
    setlocal softtabstop=4
    setlocal tabstop=8
    setlocal textwidth=79
endfunc

function! ToggleCStyle()
    if s:c_style == "style(9)"
        call StyleMine()
    else
        call Style9()
    endif
    echo s:c_style
endfunc

silent call Style9()
noremap <Leader>sc :call ToggleCStyle()<CR>
nnoremap <F3> diwi#ifndef <Esc>po#define <Esc>p3a<CR><Esc>o#endif /* <Esc>pa */<Esc>2k
inoremap <F3> <Esc>diwi#ifndef <Esc>po#define <Esc>p3a<CR><Esc>o#endif /* <Esc>pa */<Esc>2ki
