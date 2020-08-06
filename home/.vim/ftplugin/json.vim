setlocal foldmethod=syntax

" Support re-indenting JSON using `jsonfmt`
setlocal equalprg=jsonfmt

" Don't elide quotes outside the current line
if exists(':let')
    let g:vim_json_syntax_conceal = 0
endif
