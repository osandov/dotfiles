autocmd! BufWinEnter COMMIT_EDITMSG call setpos('.', [0, 1, 1, 0])
iabbrev <buffer> sob: Signed-off-by: <C-r>=system('git config user.name')[:-2]<CR> <<C-r>=system('git config user.email')[:-2]<CR>>
