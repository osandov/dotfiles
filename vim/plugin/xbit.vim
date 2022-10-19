" Set executable bit without reloading

noremap <silent> <Leader>xb :Xbit<CR>
command! Xbit call <SID>SetExecutableBit()

function! <SID>SetExecutableBit()
  let fname = expand("%")
  let oldperms = getfperm(fname)
  if len(oldperms) == 0
      echoerr "Couldn't get file permissions"
      return
  elseif len(oldperms) != 9
      echoerr "Unrecognized file permissions"
      return
  endif
  let newperms = oldperms[0:1] . "x" . oldperms[3:4] . "x" . oldperms[6:7] . "x"
  if oldperms == newperms
      echo "Executable bit already set"
  else
      call setfperm(fname, newperms)
      echo "Executable bit set"
  endif
endfunction
