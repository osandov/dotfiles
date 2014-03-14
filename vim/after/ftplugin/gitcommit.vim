" Don't save position in temporary Git commit file
autocmd! BufEnter COMMIT_EDITMSG call setpos('.', [0, 1, 1, 0])
