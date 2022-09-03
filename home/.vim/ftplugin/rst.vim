" Hook up :make to preview Sphinx docs
setlocal makeprg=make\ html

" Prevent CoC from bogging things down unnecessarily
let b:coc_suggest_disable = 1

" This isn't code, so set up automatic indent helping and rewrap
setlocal formatoptions+=tr
setlocal autoindent

" ...but disable `a` because it's not smart enough to deal with
" reStructuredText heading or `..` directive syntax
setlocal formatoptions-=a

" While it's still not smart enough to handle `=` on its own, `{motion}=` or
" `=` after visual selection is a desirable way to reformat normal segments
" of reStructuredText prose.
setlocal equalprg=pandoc\ -s\ -w\ rst

" Prevent foldmethod=syntax from causing the cursor to jitter around when
" typing quickly under vim-polyglot. It's harmless, but very distracting.
setlocal foldmethod=manual

let b:pear_tree_pairs = {
            \ ':': {'closer': ':'},
            \ '`': {'closer': '`'},
            \ }
" TODO: Figure out why \* and \*\* bug out
