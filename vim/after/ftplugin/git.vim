" % map similar to what we have for netrw.
nnoremap <buffer> <expr> % ":edit " . fnameescape(expand("%")) . "/"
