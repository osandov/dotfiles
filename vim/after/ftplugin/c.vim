" Linux kernel coding style (https://www.kernel.org/doc/html/latest/process/coding-style.html).
function! StyleLinux()
    setlocal cindent
    setlocal cinoptions=:0,l1,t0,(0
    setlocal noexpandtab
    setlocal shiftwidth=8
    setlocal softtabstop=0
    setlocal tabstop=8
    setlocal textwidth=80
    setlocal fo+=ro
    setlocal nojoinspaces
endfunction

" GNU coding style (https://www.gnu.org/prep/standards/html_node/Formatting.html#Formatting).
function! StyleGNU()
    setlocal cindent
    " From https://gcc.gnu.org/wiki/FormattingCodeForGCC.
    setlocal cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1
    setlocal noexpandtab
    setlocal shiftwidth=2
    setlocal softtabstop=2
    setlocal tabstop=8
    setlocal textwidth=79
    setlocal fo-=ro
    setlocal joinspaces
endfunction

function! s:GuessStyle()
    let comment = 0
    for line in getline(1, 1000)
        if !len(line)
            continue
        endif
        if line =~# '^\s*/\*'
            let comment = 1
        endif
        if comment
            if line =~# '\*/'
                let comment = 0
            endif
            continue
        endif
        if line =~# '^    {'
            call StyleGNU()
            return
        endif
    endfor
    call StyleLinux()
endfunction

silent call s:GuessStyle()

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
