" Use rules similar to what I enhanced the HTML support to
let b:pear_tree_pairs = {
    \ '"': {'closer': '"'},
    \ '[': {'closer': ']'},
    \ '(': {'closer': ')'},
    \ '<': {'closer': '>'},
    \ '{': {'closer': '}'},
    \ '<*>': {'closer': '</*>', 'until': '[^a-zA-Z0-9-._]', 'not_like': '/$'},
    \ '<!--': {'closer': '--'}
    \ }

set sw=2 sts=2
