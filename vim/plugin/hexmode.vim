" Hexmode

command! -bar ToggleHex call ToggleHex()
nnoremap <Leader>hx :ToggleHex<CR>

command! -bar HexRefresh call HexRefresh()
nnoremap <Leader>hr :HexRefresh<CR>

" helper function to toggle hex mode
function! ToggleHex()
    let l:modified=&mod
    let l:oldreadonly=&readonly
    let &readonly=0
    let l:oldmodifiable=&modifiable
    let &modifiable=1

    if exists('b:hexmode') && b:hexmode
        " restore old options
        let &ft=b:oldft
        if !b:oldbin
            setlocal nobinary
        endif
        " set status
        let b:hexmode=0
        " return to normal editing
        silent %!xxd -r
    else
        " save old options
        let b:oldft=&ft
        let b:oldbin=&bin
        " set new options
        setlocal binary " make sure it overrides any textwidth, etc.
        let &ft="xxd"

        " set status
        let b:hexmode=1
        " switch to hex editor
        silent %!xxd
    endif

    " restore values for modified and read-only state
    let &mod=l:modified
    let &readonly=l:oldreadonly
    let &modifiable=l:oldmodifiable
endfunction

function! HexRefresh()
    call <SID>PreWrite()
    call <SID>PostWrite()
endfunction

" Workaround to prevent repeating hexmode when reloading
au! BufRead * :let b:hexmode=0

" Write the binary, not the hexdump
au! BufWritePre * :call <SID>PreWrite()
au! BufWritePost * :call <SID>PostWrite()

function! <SID>PreWrite()
    if exists('b:hexmode') && b:hexmode
        let s:line = line(".")
        let s:column = col(".")
        if !b:oldbin
            setlocal nobinary
        endif
        silent %!xxd -r
    endif
endfunction

function! <SID>PostWrite()
    if exists('b:hexmode') && b:hexmode
        silent %!xxd
        setlocal binary
        call cursor(s:line, s:column)
    endif
endfunction
