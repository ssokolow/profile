" default_256_fixed.vim: a new colorscheme by ssokolow
" Written By: Charles E. Campbell, Jr.'s ftplugin/hicolors.vim
" Date: Sat 19 Apr 2014 04:06:48 AM EDT

" ---------------------------------------------------------------------
" Standard Initialization:
set t_Co=256
set bg=light
hi clear
if exists( "syntax_on")
 syntax reset
endif
let g:colors_name="default_256_fixed"

" ---------------------------------------------------------------------
" Highlighting Commands:
hi SpecialKey     ctermfg=26 guifg=Blue
hi NonText        ctermfg=32 gui=bold guifg=Blue
hi Directory      ctermfg=26 guifg=Blue
hi ErrorMsg       term=standout ctermfg=15 ctermbg=1 guifg=White guibg=Red
hi IncSearch      term=reverse cterm=reverse gui=reverse
hi Search         ctermfg=232 ctermbg=11 guibg=Yellow
hi MoreMsg        term=bold ctermfg=2 gui=bold guifg=SeaGreen
hi ModeMsg        term=bold cterm=bold gui=bold
hi LineNr         term=underline ctermfg=130 guifg=Brown
hi CursorLineNr   term=bold ctermfg=130 gui=bold guifg=Brown
hi Question       term=standout ctermfg=2 gui=bold guifg=SeaGreen
hi StatusLine     term=bold,reverse cterm=bold,reverse gui=bold,reverse
hi StatusLineNC   term=reverse cterm=reverse gui=reverse
hi VertSplit      term=reverse cterm=reverse gui=reverse
hi Title          term=bold ctermfg=5 gui=bold guifg=Magenta
hi Visual         ctermfg=239 ctermbg=7 guibg=LightGrey
hi VisualNOS      term=bold,underline cterm=bold,underline gui=bold,underline
hi WarningMsg     term=standout ctermfg=1 guifg=Red
hi WildMenu       term=standout ctermfg=0 ctermbg=11 guifg=Black guibg=Yellow
hi Folded         term=standout ctermfg=4 ctermbg=248 guifg=DarkBlue guibg=LightGrey
hi FoldColumn     term=standout ctermfg=4 ctermbg=248 guifg=DarkBlue guibg=Grey
hi DiffAdd        ctermfg=10 ctermbg=0 guibg=#98FF98
hi DiffChange     ctermfg=11 ctermbg=0 guibg=#ffFF78
hi DiffDelete     term=bold ctermfg=1 ctermbg=0 gui=bold guifg=Blue guibg=#FFC8C8
hi DiffText       cterm=bold ctermfg=240 ctermbg=9 gui=bold guibg=Red
hi SignColumn     term=standout ctermfg=4 ctermbg=248 guifg=DarkBlue guibg=Grey
hi Conceal        ctermfg=7 ctermbg=242 guifg=LightGrey guibg=DarkGrey
hi SpellBad       ctermfg=236 ctermbg=224 gui=undercurl guisp=Red
hi SpellCap       ctermfg=236 ctermbg=81 gui=undercurl guisp=Blue
hi SpellRare      ctermfg=236 ctermbg=225 gui=undercurl guisp=Magenta
hi SpellLocal     ctermfg=236 ctermbg=14 gui=undercurl guisp=DarkCyan
hi Pmenu          ctermfg=7 ctermbg=8 guibg=LightMagenta
hi PmenuSel       ctermfg=0 ctermbg=7 guibg=Grey
hi PmenuSbar      ctermfg=236 ctermbg=248 guibg=Grey
hi PmenuThumb     ctermbg=0 guibg=Black
hi TabLine        term=underline cterm=underline ctermfg=0 ctermbg=7 gui=underline guibg=LightGrey
hi TabLineSel     term=bold cterm=bold gui=bold
hi TabLineFill    term=reverse cterm=reverse gui=reverse
hi CursorColumn   ctermfg=242 ctermbg=7 guibg=Grey90
hi CursorLine     term=underline cterm=underline guibg=Grey90
hi ColorColumn    term=reverse ctermbg=224 guibg=LightRed
hi Cursor         guifg=bg guibg=fg
hi lCursor        guifg=bg guibg=fg
hi MatchParen     ctermfg=236 ctermbg=14 guibg=Cyan
hi Comment        ctermfg=27 guifg=Blue
hi Constant       term=underline ctermfg=1 guifg=Magenta
hi Special        term=bold ctermfg=5 guifg=SlateBlue
hi Identifier     term=underline ctermfg=6 guifg=DarkCyan
hi Statement      term=bold ctermfg=130 gui=bold guifg=Brown
hi PreProc        term=underline ctermfg=5 guifg=Purple
hi Type           term=underline ctermfg=2 gui=bold guifg=SeaGreen
hi Underlined     term=underline cterm=underline ctermfg=5 gui=underline guifg=SlateBlue
hi Ignore         ctermfg=15 guifg=bg
hi Error          term=reverse ctermfg=15 ctermbg=9 guifg=White guibg=Red
hi Todo           term=standout ctermfg=0 ctermbg=11 guifg=Blue guibg=Yellow
