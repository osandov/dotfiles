" Cscope settings for vim

if has("cscope")
    """"""""""""" Standard cscope/vim boilerplate

    " use both cscope and ctag for 'ctrl-]', ':ta', and 'vim -t'
    set cscopetag

    " check cscope for definition of a symbol before checking ctags: set to 1
    " if you want the reverse search order.
    set csto=0

    " add any cscope database in current directory
    if filereadable("cscope.out")
        cs add cscope.out
    " else add the database pointed to by environment variable
    elseif $CSCOPE_DB != ""
        cs add $CSCOPE_DB
    endif

    " show msg when any other cscope db added
    set cscopeverbose

    """"""""""""" My cscope/vim key mappings
    cnoreabbrev tcs tab scs

    cnoreabbrev csa cs add
    cnoreabbrev csf cs find
    cnoreabbrev csk cs kill
    cnoreabbrev csr cs reset
    cnoreabbrev css cs show
    cnoreabbrev csh cs help

    cnoreabbrev tcsa tab scs add
    cnoreabbrev tcsf tab scs find
    cnoreabbrev tcsk tab scs kill
    cnoreabbrev tcsr tab scs reset
    cnoreabbrev tcss tab scs show
    cnoreabbrev tcsh tab scs help

    cnoreabbrev scsa scs add
    cnoreabbrev scsf scs find
    cnoreabbrev scsk scs kill
    cnoreabbrev scsr scs reset
    cnoreabbrev scss scs show
    cnoreabbrev scsh scs help

    cnoreabbrev vcsa vert scs add
    cnoreabbrev vcsf vert scs find
    cnoreabbrev vcsk vert scs kill
    cnoreabbrev vcsr vert scs reset
    cnoreabbrev vcss vert scs show
    cnoreabbrev vcsh vert scs help

    nnoremap <C-\>s :cs find s <C-R>=expand("<cword>")<CR><CR>
    nnoremap <C-\>g :cs find g <C-R>=expand("<cword>")<CR><CR>
    nnoremap <C-\>c :cs find c <C-R>=expand("<cword>")<CR><CR>
    nnoremap <C-\>t :cs find t <C-R>=expand("<cword>")<CR><CR>
    nnoremap <C-\>e :cs find e <C-R>=expand("<cword>")<CR><CR>
    nnoremap <C-\>f :cs find f <C-R>=expand("<cfile>")<CR><CR>
    nnoremap <C-\>i :cs find i ^<C-R>=expand("<cfile>")<CR>$<CR>
    nnoremap <C-\>d :cs find d <C-R>=expand("<cword>")<CR><CR>

    nnoremap <C-\><C-\>s :tab scs find s <C-R>=expand("<cword>")<CR><CR>
    nnoremap <C-\><C-\>g :tab scs find g <C-R>=expand("<cword>")<CR><CR>
    nnoremap <C-\><C-\>c :tab scs find c <C-R>=expand("<cword>")<CR><CR>
    nnoremap <C-\><C-\>t :tab scs find t <C-R>=expand("<cword>")<CR><CR>
    nnoremap <C-\><C-\>e :tab scs find e <C-R>=expand("<cword>")<CR><CR>
    nnoremap <C-\><C-\>f :tab scs find f <C-R>=expand("<cfile>")<CR><CR>
    nnoremap <C-\><C-\>i :tab scs find i ^<C-R>=expand("<cfile>")<CR>$<CR>
    nnoremap <C-\><C-\>d :tab scs find d <C-R>=expand("<cword>")<CR><CR>

    nnoremap <C-\><C-S>s :scs find s <C-R>=expand("<cword>")<CR><CR>
    nnoremap <C-\><C-S>g :scs find g <C-R>=expand("<cword>")<CR><CR>
    nnoremap <C-\><C-S>c :scs find c <C-R>=expand("<cword>")<CR><CR>
    nnoremap <C-\><C-S>t :scs find t <C-R>=expand("<cword>")<CR><CR>
    nnoremap <C-\><C-S>e :scs find e <C-R>=expand("<cword>")<CR><CR>
    nnoremap <C-\><C-S>f :scs find f <C-R>=expand("<cfile>")<CR><CR>
    nnoremap <C-\><C-S>i :scs find i ^<C-R>=expand("<cfile>")<CR>$<CR>
    nnoremap <C-\><C-S>d :scs find d <C-R>=expand("<cword>")<CR><CR>

    nnoremap <C-\><C-V>s :vert scs find s <C-R>=expand("<cword>")<CR><CR>
    nnoremap <C-\><C-V>g :vert scs find g <C-R>=expand("<cword>")<CR><CR>
    nnoremap <C-\><C-V>c :vert scs find c <C-R>=expand("<cword>")<CR><CR>
    nnoremap <C-\><C-V>t :vert scs find t <C-R>=expand("<cword>")<CR><CR>
    nnoremap <C-\><C-V>e :vert scs find e <C-R>=expand("<cword>")<CR><CR>
    nnoremap <C-\><C-V>f :vert scs find f <C-R>=expand("<cfile>")<CR><CR>
    nnoremap <C-\><C-V>i :vert scs find i ^<C-R>=expand("<cfile>")<CR>$<CR>
    nnoremap <C-\><C-V>d :vert scs find d <C-R>=expand("<cword>")<CR><CR>
endif
