function! s:Style9()
    let s:c_style = "Style 9"
    echo s:c_style
    setlocal shiftwidth=8
    setlocal noexpandtab
endfunc

function! s:StyleMine()
    let s:c_style = "Style Mine"
    echo s:c_style
    setlocal shiftwidth=4
    setlocal expandtab
endfunc

function! g:ToggleCStyle()
    if s:c_style == "Style 9"
        call s:StyleMine()
    else
        call s:Style9()
    endif
endfunc

if search('^\t', 'n', 0, 100)
    silent call s:Style9()
el 
    silent call s:StyleMine()
en

noremap <Leader>sc :call g:ToggleCStyle()<CR>
