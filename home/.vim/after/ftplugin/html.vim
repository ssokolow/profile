" Let pear-tree help even more with HTML tags
" (This was empirically demonstrated to work together to allow completing both
"  the initial <> and the overall <!-- --> or <...></...>)
let b:pear_tree_pairs['<'] = {'closer': '>'}
let b:pear_tree_pairs['<!--'] = {'closer': '--'}
