" Linux kernel coding style (linux/Documentation/process/coding-style.rst).
setlocal cindent
setlocal cinoptions=:0,t0,(0
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
