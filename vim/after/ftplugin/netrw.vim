" Override the default netrw % map to open a new file in the current directory
" with a version that allows for tab completion.
nnoremap <buffer> <expr> % ":edit " . fnameescape(fnamemodify(b:netrw_curdir, ":~:.")) . "/"
