let g:ale_markdown_mdl_options = '-s ~/.vim/mdl_style'
let b:ale_fixers = ['prettier', 'remove_trailing_lines', 'trim_whitespace']
let b:ale_javascript_prettier_options = '--prose-wrap always'

" Harmonize <Tab> behaviour with Prettier
setlocal softtabstop=2 shiftwidth=2

" This isn't code, so set up automatic indent helping
setlocal formatoptions+=r
setlocal autoindent

" ...but disable `t` because it's not smart enough to deal with fenced code
" blocks. Let Prettier deal with that level of rewrapping on save and disable
" `a` because it breaks something fierce when trying to put links in bulleted
" lists with word-wrapping.
setlocal formatoptions-=ta

" Don't trip me up when I'm trying to edit Markdown hyperlinks
let b:indentLine_concealcursor = 'nc'

" In practical terms, I find it better to be able to see URL flubs without
" actively checking every hyperlink, and then to check the rendered form
" using a proper renderer like grip
if exists(':let')
    let g:vim_markdown_conceal = 0
    let g:vim_markdown_conceal_code_blocks = 0
endif
