" Linux kernel coding style (linux/Documentation/process/coding-style.rst).
setlocal cindent
setlocal cinoptions=:0,l1,t0,(0
setlocal noexpandtab
setlocal shiftwidth=8
setlocal softtabstop=0
setlocal tabstop=8
setlocal textwidth=80

nnoremap <F3> diwi#ifndef <Esc>po#define <Esc>p3a<CR><Esc>o#endif /* <Esc>pa */<Esc>2k
inoremap <F3> <Esc>diwi#ifndef <Esc>po#define <Esc>p3a<CR><Esc>o#endif /* <Esc>pa */<Esc>2ki
vnoremap <LocalLeader>0 <Esc>`<O#if 0<Esc>`>o#endif<Esc>
nnoremap <LocalLeader>{ A<Space>{<Esc>jo}<Esc>k^
nnoremap <LocalLeader>} $diB"_daB"_Dp

function! s:addLineContinuations(first, last)
    let lines = getline(a:first, a:last)
    call map(lines, {key, val -> substitute(val, '[[:space:]\\]\+$', '', 'g')})
    let tabstops = (max(map(copy(lines), 'strdisplaywidth(v:val)')) + &tabstop) / &tabstop
    let numcontinue = a:last - a:first
    let nextline = getline(a:last + 1)
    if nextline[-1:] == '\'
        let tabstops = max([tabstops, (strdisplaywidth(nextline) - 1) / &tabstop])
        let numcontinue += 1
    elseif a:first == a:last && getline(a:first)[-1:] == '\'
        let numcontinue += 1
    endif
    call map(lines, {key, val -> (key < numcontinue) ? (val . repeat("\t", tabstops - strdisplaywidth(val) / &tabstop) . '\') : val})
    call setline(a:first, lines)
endfunction

function! s:addLineContinuationsRange() range
    call s:addLineContinuations(a:firstline, a:lastline)
endfunction

nnoremap <LocalLeader>\ :call <SID>addLineContinuations(getcurpos()[1], getcurpos()[1])<CR>
vnoremap <LocalLeader>\ :call <SID>addLineContinuationsRange()<CR>
