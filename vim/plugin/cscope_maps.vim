" CSCOPE settings for vim           

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
    nnoremap <C-\>s :cs find s <C-R>=expand("<cword>")<CR><CR>
    nnoremap <C-\>g :cs find g <C-R>=expand("<cword>")<CR><CR>
    nnoremap <C-\>c :cs find c <C-R>=expand("<cword>")<CR><CR>
    nnoremap <C-\>t :cs find t <C-R>=expand("<cword>")<CR><CR>
    nnoremap <C-\>e :cs find e <C-R>=expand("<cword>")<CR><CR>
    nnoremap <C-\>f :cs find f <C-R>=expand("<cfile>")<CR><CR>
    nnoremap <C-\>i :cs find i ^<C-R>=expand("<cfile>")<CR>$<CR>
    nnoremap <C-\>d :cs find d <C-R>=expand("<cword>")<CR><CR>

    nnoremap <C-Space>s :scs find s <C-R>=expand("<cword>")<CR><CR>
    nnoremap <C-Space>g :scs find g <C-R>=expand("<cword>")<CR><CR>
    nnoremap <C-Space>c :scs find c <C-R>=expand("<cword>")<CR><CR>
    nnoremap <C-Space>t :scs find t <C-R>=expand("<cword>")<CR><CR>
    nnoremap <C-Space>e :scs find e <C-R>=expand("<cword>")<CR><CR>
    nnoremap <C-Space>f :scs find f <C-R>=expand("<cfile>")<CR><CR>
    nnoremap <C-Space>i :scs find i ^<C-R>=expand("<cfile>")<CR>$<CR>
    nnoremap <C-Space>d :scs find d <C-R>=expand("<cword>")<CR><CR>

    nnoremap <C-S-Space>s :vert scs find s <C-R>=expand("<cword>")<CR><CR>
    nnoremap <C-S-Space>g :vert scs find g <C-R>=expand("<cword>")<CR><CR>
    nnoremap <C-S-Space>c :vert scs find c <C-R>=expand("<cword>")<CR><CR>
    nnoremap <C-S-Space>t :vert scs find t <C-R>=expand("<cword>")<CR><CR>
    nnoremap <C-S-Space>e :vert scs find e <C-R>=expand("<cword>")<CR><CR>
    nnoremap <C-S-Space>f :vert scs find f <C-R>=expand("<cfile>")<CR><CR>
    nnoremap <C-S-Space>i :vert scs find i ^<C-R>=expand("<cfile>")<CR>$<CR>
    nnoremap <C-S-Space>d :vert scs find d <C-R>=expand("<cword>")<CR><CR>

    nnoremap <C-Space><C-Space>s :scs find s <C-R>=expand("<cword>")<CR><CR><C-W>T
    nnoremap <C-Space><C-Space>g :scs find g <C-R>=expand("<cword>")<CR><CR><C-W>T
    nnoremap <C-Space><C-Space>c :scs find c <C-R>=expand("<cword>")<CR><CR><C-W>T
    nnoremap <C-Space><C-Space>t :scs find t <C-R>=expand("<cword>")<CR><CR><C-W>T
    nnoremap <C-Space><C-Space>e :scs find e <C-R>=expand("<cword>")<CR><CR><C-W>T
    nnoremap <C-Space><C-Space>f :scs find f <C-R>=expand("<cfile>")<CR><CR><C-W>T
    nnoremap <C-Space><C-Space>i :scs find i ^<C-R>=expand("<cfile>")<CR>$<CR><C-W>T
    nnoremap <C-Space><C-Space>d :scs find d <C-R>=expand("<cword>")<CR><CR><C-W>T
endif
