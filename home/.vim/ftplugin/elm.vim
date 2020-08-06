let b:ale_fixers = ['elm-format', 'remove_trailing_lines', 'trim_whitespace']

" Workaround for some brokenness that keeps slamming my folds shut when I save
" the file... but only in Elm
setlocal foldmethod=indent
setlocal foldlevel=99
