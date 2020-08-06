" Set up an 'escpos' filetype which makes the width of my thermal printer's
" paper clear and sets up :make to print things.
setlocal textwidth=31
setlocal colorcolumn=32
setlocal makeprg=~/bin/escpos-cli.py\ print\ %
