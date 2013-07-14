command! -range Reflow <line1>,<line2>call <SID>Reflow()

function! <SID>Reflow() range
    echo "Firstline: " . a:firstline . ", Lastline: " . a:lastline
    let l:lines = a:lastline - a:firstline + 1
    exec "normal! " l:lines . "J^"
    while 1
        exec "normal! " &textwidth "l"
        let l:column = col(".")
        if l:column <= &textwidth
            break
        else
            exec "normal Bhs\<CR>"
        endif
    endwhile
endfunction
