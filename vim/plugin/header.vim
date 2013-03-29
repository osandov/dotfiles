" Edits the corresponding header or source file for the current buffer

command! -bar Header call s:HeaderOrSource()

let s:HeaderExtensions = [".h", ".hh", ".hpp", ".hxx", ".h++"]
let s:SourceExtensions = [".c", ".cc", ".cpp", ".cxx", ".c++"]

function! s:HeaderOrSource()
    try
        let l:extension = "." . fnamemodify(bufname("%"), ":e")
        if index(s:HeaderExtensions, l:extension) >= 0
            call s:Source()
        elseif index(s:SourceExtensions, l:extension) >= 0
            call s:Header()
        else
            throw "Unrecognized filename extension"
        end
    catch /.*/
        echohl ErrorMsg
        echo v:exception
        echohl None
    endtry
endfunction

function! s:Header()
    let l:basename = fnamemodify(bufname("%"), ":r")
    for extension in s:HeaderExtensions
        let l:file = l:basename . extension
        if filereadable(l:file)
            execute "edit " . l:file
            return
        endif
    endfor
    throw "Could not find header"
endfunction

function! s:Source()
    let l:basename = fnamemodify(bufname("%"), ":r")
    for extension in s:SourceExtensions
        let l:file = l:basename . extension
        if filereadable(l:file)
            execute "edit " . l:file
            return
        endif
    endfor
    throw "Could not find source"
endfunction
