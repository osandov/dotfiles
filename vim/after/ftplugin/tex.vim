let b:tex_flavor = 'pdflatex'
compiler tex
set makeprg=pdflatex\ \-file\-line\-error\ \-interaction=nonstopmode\ %
set errorformat=%f:%l:\ %m
