
" Source: http://vim.wikia.com/wiki/Cleanup_your_HTML
vmap <buffer> ,x :!tidy -q -i --show-errors 0<CR>
nmenu 40.600 Tools.Run\ HTMLTidy<Tab>,x ggvG,x
vmenu 40.600 Tools.Run\ HTMLTidy<Tab>,x ,x
