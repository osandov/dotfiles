" Hexmode

command -bar Hexmode call ToggleHex()
nnoremap <C-H> :Hexmode<CR>
inoremap <C-H> <Esc>:Hexmode<CR>
vnoremap <C-H> :<C-U>Hexmode<CR>

" helper function to toggle hex mode
function! ToggleHex()
    " hex mode should be considered a read-only operation
    " save values for modified and read-only for restoration later,
    " and clear the read-only flag for now
    let l:modified=&mod
    let l:oldreadonly=&readonly
    let &readonly=0
    let l:oldmodifiable=&modifiable
    let &modifiable=1
    if !exists("b:hexmode") || !b:hexmode
        " save old options
        let b:oldft=&ft
        let b:oldbin=&bin
        " set new options
        setlocal binary " make sure it overrides any textwidth, etc.
        let &ft="xxd"
        " set status
        let b:hexmode=1
        " switch to hex editor
        %!xxd
    else
        " restore old options
        let &ft=b:oldft
        if !b:oldbin
            setlocal nobinary
        endif
        " set status
        let b:hexmode=0
        " return to normal editing
        %!xxd -r
    endif
    " restore values for modified and read-only state
    let &mod=l:modified
    let &readonly=l:oldreadonly
    let &modifiable=l:oldmodifiable
endfunction

function! <SID>PreWrite()
    let s:line = line(".")
    let s:column = col(".")
    if exists("b:hexmode") && b:hexmode
        if !b:oldbin
            setlocal nobinary
        endif
        silent %!xxd -r
    endif
endfunction

function! <SID>PostWrite()
    if exists("b:hexmode") && b:hexmode
        setlocal binary
        silent %!xxd
    endif
    call cursor(s:line, s:column)
endfunction

" Write the binary, not the hexdump
au! BufWritePre * :call <SID>PreWrite()
au! BufWritePost * :call <SID>PostWrite()
