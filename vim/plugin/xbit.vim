" Set executable bit without reloading

noremap <Leader>xb :<C-U>Xbit<CR>
command! Xbit call <SID>SetExecutableBit()

function! <SID>SetExecutableBit()
  let fname = expand("%:p")
  checktime
  execute "au FileChangedShell " . fname . " :echo"
  silent !chmod +x %
  checktime
  execute "au! FileChangedShell " . fname
endfunction
