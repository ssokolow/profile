" Stephan Sokolow's .vimrc (WIP)
" If you are unfamiliar with vim's folding commands, type zR.

" {{{ Quick Reference
"
" File Navigation And Management:
"  \s           Save Current Session
"  \p           Open Session Manager
"  \[           Toggle NERDTree
"  \]           Toggle MiniBufExplorer
"
"  :Rename      Rename file attached to the current buffer
"
"  :A           Switch between source and header file
"  :AS/:AV      Split horiz/vert and switch to matching source/header
"
"  <C-]>        Jump to tag under cursor.
"  <C-T>        Undo the most recent jump to tag.
"
"  [o           Open previous file in the directory. (alphabetically)
"  ]o           Open next file in the directory. (alphabetically)
"
"  :G           'git grep' on the provided string
"  <C-X> G      'git grep' on the word under the cursor
"
" Navigation:
"  gv           Re-select contents of previous visual-mode selection.
"
"  */#          Jump to next/previous instance of exact word under cursor
"  g*/g#        Jump to next/previous instance of word under cursor as substring
"
"  %            Jump to next if/then clause or matching paren
"  g%           Jump to previous if/then clause or matching paren
"
"  ]m           Jump to start of next method/class
"  [m           Jump to start of previous method/class
"  ]M           Jump to end of next method/class
"  [M           Jump to end of previous method/class
"
"  zo           Open fold
"  zc           Close fold
"  zr           Reduce folding (open one level of folds)
"  zm           More folding (close one level of folds)
"  zR           Open all folds
"  zM           Close all folds
"
"  TODO: Find or set an insert-mode binding for moving word-by-word
"
" Noteworthy Motions:
"  i {char}     Everything inside paired {char} centered on the cursor
"  f/F {char}   Move forward/backward onto [count]'th occurrence of {char}
"  t/T {char}   Move forward/backward 'til before/after [count]'th occurrence of {char}
"  ;/,          Repeat previous same/opposite f/t/F/T motion [count] times.
"
"  w/W/b/B      [count] words forward/back, land on start (by non-word/space chars)
"  e/E/ge/gE    [count] words forward/back, land on end (by non-word/space chars)
"
"  (/)          [count] sentences back/forward.
"  {/}          [count] paragraphs back/forward.
"
"  G            Go to line [count]
"  %            Go to [count] percent of the way through the file
"  go           Go to byte [count] of the file
"
" Editing:
"  Tab          Indent/Snippets/Omni-Completion (Smart)
"  <C-P>        Omni-Completion (when Smart isn't smart enough)
"  <C-V>        Visual Block mode (A.K.A. column mode)
"
"  <C-A>/<C-X>  Increment/decrement number/date/time/numeral under cursor.
"               (Also supports letters of the alphabet in visual mode)
"  <C-X> /      Close the last open HTML/PHP/Django/eRuby tag
"  <C-X> Space  Create tag pair from the typed word (single line)
"  <C-X> Enter  Create tag pair from the typed word (multi-line)
"
"  \cc          Comment selected lines
"  \cu          Uncomment selected lines
"
"  >>           Indent selected lines
"  <<           Unindent selected lines
"
"  [xx          XML Encode line/selection
"  ]xx          XML Decode line/selection
"  [uu          URL Encode line/selection
"  [uu          URL Encode line/selection
"  ]yy          C String Escape line/selection
"  ]yy          C String Unescape line/selection
"
"  zf           Create fold  (Inserts markers around selection if foldmethod=marker)
"
"  gg=G         Reindent the entire file according to the current indent setup
"               (Assuming 'equalprg' hasn't redefined the meaning of =)
"
"  :Loremipsum [word count]
"               Insert placeholder text
"
"  Build An Incremented Sequence From A Selected Column In Visual Block Mode:
"  :I  [#]      Left-Justified  (Supply # for non-default increment)
"  :II [#] [F]  Right-Justified (Supply F for non-default padding character)
"
"  Note: Variants also allow incrementing of dates, day names, and hexadecimal,
"  octal, and roman numerals.
"
"  Motions Requiring Operator Or Visual Mode:
"   at          HTML/XML element (tags) at cursor plus contents (eg. dat)
"   it          Just contents of HTML/XML element (tags) at cursor (eg. dit)
"
"  Surround:
"   Where X and Y are quotes, parens, or HTML tags...
"   Normal Mode:
"    dsX    Delete containing X
"    csXY   Replace containing X with Y
"    cstY   Replace containing tag with Y
"    cspY   Wrap current paragraph with Y
"    yssY   Wrap current line's contents with Y
"    ySSY   Indent current line and wrap with Y on their own lines
"   Visual Mode:
"    SY     Wrap selection with Y
"   Insert ModE:
"    <C-S>X Insert paired X and position the cursor in between
"
"  Vis:
"   Use visual mode to select and then...
"    :B <cmd>   Apply a command to selected region
"    :S <pat>   Search only selected region
"
" Display Control:
"  [count] <C-W> +/-/</> Resize the current pane
"  <C-W> _    Maximize current pane
"  <C-W> =    Make all panes equal size
"
"  <C-W><C-W> Cycle pane focus (Backwards to allow easy flipping between two)
"  <C-W><dir> Move focus to adjoining pane
"
"  <C-W> s/v  Split Horizontally/Vertically
"  <C-W> c    Close current pane if it wouldn't discard unsaved contents (:clo)
"  <C-w> ]    Split window and jump to tag under cursor
"  <C-w> i    Split window and jump to declaration of identifier under cursor
"
"  <C-N><C-N> Toggle line numbers
"  <C-L>      Hide search result highlights
"
" }}}
" {{{ Non-QuickRef Notes on This Configuration:
"
" - A plugin provides "Smart Home/End" (like in Visual C++, apparently)
" - Saving non-M4/Make/diff/mail files automatically removes trailing whitespace
" - In supported file formats, saving automatically runs a syntax check
" - TODO: Complete this list
"
" }}}
" {{{ Notes on my rationale:
" - I keep Select mode off because Visual mode is more useful and I can get
"   Select-mode behaviour by just typing an extra c after selecting.
" - I've rebound the up/down arrows and home/end to take soft-wrap into account
"   because it's what I'm already used to and, in the case of home/end,
"   it'll always be a simpler motion than g0 and g$.
" - Whenever it can be done suitably reliably, I let Vim do things for me.
"   (eg. stripping trailing whitespace and using the DetectIndent plugin)
" - Whenever it can be done quickly and without being overly nitpicky, I let vim
"   run static analysis on files on save and display the results in the quickfix
"   window.
" }}}
" {{{ TODO:
" * Report to Ciaran McCreesh that DetectIndent trips over /*\n*\n*\n*/
" * Fix the PyFlakes-quickfix integration so the quickfix lines are clickable
" * Decide whether to use PyChecker or PyLint for Python :make
" * Find or write a script which strips the former next line's indenting when
"   I remove a newline character with the Delete key.
" * Set up some concise prev/next tab keybindings
" * Choose a different color scheme for the ncurses omni-completion popup
" * Decide how I want NERDTree to behave relative to cd.
" * Set up and memorize a suitable set of snipMate snippets.
" * Set up on-save quickfix lint for CSS
" * Consider using signs for inline handling of things like diff, quickfix, etc.
" * Figure out how to properly handle spaces in filepaths for makeprg. (eg. tidy)
" * Set up filetype-specific equalprg strings for HTMLTidy, CSSTidy, etc.
"   and/or figure out the keybinding to reformat based on the vim indent defs.
" * Figure out how to solve my disagreement with gVim over what constitutes
"   an acceptable response to existing swap files.
" * Adjust my session-saving keybinding so it asks for confirmation somehow
"   if no prior session was saved rather than dumping a Session.vim into the
"   working directory.
" * Figure out why, with comment formatting enabled, formatoptions wants to
"   word-wrap after every word in this file.
" ----
" * http://vim.wikia.com/wiki/Integration_with_PyUnit_testing_framework
" * http://www.vim.org/scripts/script.php?script_id=974
" * http://www.vim.org/scripts/script.php?script_id=1881
" * http://vim.wikia.com/wiki/VimTip1
" * http://vim.wikia.com/wiki/Git_grep
" * http://www.vim.org/scripts/script.php?script_id=90
" * http://vim.wikia.com/wiki/VimTip224
" * http://vim.wikia.com/wiki/GNU_Screen_integration
" * http://vim.wikia.com/wiki/Automatically_create_and_update_cscope_database
" * http://www.vim.org/scripts/script.php?script_id=2448
" * http://www.vim.org/scripts/script.php?script_id=3010
" * http://vim.wikia.com/wiki/Simple_programmers_TODO_list_using_grep_and_quickfix
" * http://www.vim.org/scripts/script.php?script_id=1577
" * http://vim.wikia.com/wiki/Switch_between_Vim_window_splits_easily
" * Look into merging tag_signature.vim with
"   http://vim.wikia.com/wiki/Use_balloonexpr_effectively
" * http://www.vim.org/scripts/script.php?script_id=1218
" * http://www.vim.org/scripts/script_search_results.php?keywords=php+indent&script_type=&order_by=rating&direction=descending&search=search
" * http://stackoverflow.com/questions/313359/annoying-vim-unindent-rules
" ----
" * http://vimdoc.sourceforge.net/htmldoc/quickfix.html#quickfix
" * http://vim.runpaint.org/
" * http://www.vex.net/~x/python_and_vim.html
" * http://vimdoc.sourceforge.net/htmldoc/options.html#modeline
" * http://vimdoc.sourceforge.net/htmldoc/usr_40.html#40.1
" * http://vim.wikia.com/wiki/Main_Page
" * http://vimdoc.sourceforge.net/vimfaq.html
" * http://vimdoc.sourceforge.net/htmldoc/usr_toc.html
" * http://www.sm.luth.se/csee/courses/smd/139/smd139_vi.pdf
" * http://vimdoc.sourceforge.net/htmldoc/motion.html#operator
" * /home/ssokolow/incoming/vimbook-OPL.pdf
" * http://www.viemu.com/a-why-vi-vim.html
" * http://www.gentoo.org/doc/en/vi-guide.xml
" * http://www.vim.org/scripts/script.php?script_id=2120
" * http://vim.wikia.com/wiki/Best_Vim_Tips
" * http://vim.runpaint.org/navigation/bookmarking-lines-with-visible-markers/
" * http://vimdoc.sourceforge.net/htmldoc/quickfix.html#errorformat
" * http://vim.wikia.com/wiki/Folding
" * http://amix.dk/blog/post/19132
" * https://sites.google.com/site/linuxpebbles/cool-tricks/some-of-my-favorite-vim-tips/vim-folding-commands#TOC-Using-the-mouse

" }}}
" {{{ Stuff to build habits for:
" * http://www.catonmat.net/series/vim-plugins-you-should-know-about
" * Splitting and unsplitting:
"  - http://blogs.sourceallies.com/2009/11/vim-splits-an-introduction/
"  - http://jmcpherson.org/windows.html
" }}}
" {{{ HOWTO Reminders for Things I May Eventually Want
" Originally from:
" http://the-shaolin.blogspot.com/2004/12/my-own-2-cent-vim-tip.html
" ab TODO: ssokolow :r!date +\%Y-\%m-\%dkJA TODO:
" ab FIXME: ssokolow :r!date +\%Y-\%m-\%dkJA FIXME:
" }}}

" {{{ Configuration

set nocompatible
set modeline

" I don't like my apps bugging me about donations.
set shortmess+=I

" Don't treat word-wrapped lines as an 'all or nothing' thing when displaying.
set display+=lastline
set scrolloff=2 " I like to have a two-line 'preview' when scrolling

" I want a decent status line
set showcmd     " Show in-progress commands so I can figure out what the heck I accidentally hit.

" Make tabs and trailing whitespace visible
set list
set listchars=tab:»·,trail:· " show tabs and trailing spaces

" Only word-wrap comments and word-wrap them at 80 characters.
set formatoptions-=t     " No word-wrap inside code.
set formatoptions+=croql " Make the behaviour I'm used to explicit
set textwidth=80

" I prefer 4-space indentation by default
set expandtab
set tabstop=4
set softtabstop=4
set shiftwidth=4

" TODO: Get these cooperating. (n seems to require t)
"set formatoptions+=n
"set formatlistpat="^\s*\(\d\+[\]:.)}\t ]\|[-*]\)\s*"

" Make my sessions a bit more like projects and less like vimrc overrides.
set sessionoptions=blank,curdir,folds,help,resize,slash,tabpages,unix,winpos,winsize

" }}}
" {{{ Configuration (Optional Vim Features)

" Make searching more efficient
if has("extra_search")
	set incsearch
	set hlsearch
	set ignorecase
	set smartcase
endif

" Let's default to syntax-based folding since it's the most automatic
if exists("+folding")
	set foldmethod=indent
endif

" I want full mouse support when using a Yakuake-->screen-->vim stack.
if exists("+mouse")
	set ttymouse=xterm2
	set mouse=a
endif

" Set up more comfortable filesystem navigation
if exists("+wildmenu")
	set wildmenu
endif
if exists("+wildignore")
	set wildignore+=.pyc,.pyo,.class
else
	set suffixes+=.pyc,.pyo,.class
endif

" Use 'ack' as my grep program since it's more comfortable for me
if executable("ack")
	set grepprg=ack\ -a
endif

" }}}
" {{{ Configuration (Plugins)
if exists(":let")
	let g:ragtag_global_maps = 1
	let g:pcs_check_when_saving = 1
	let g:SuperTabDefaultCompletionType = "context"

	" I prefer 4-character space indentation as my default for DetectIndent too
	let g:detectindent_preferred_expandtab = 1
	let g:detectindent_preferred_indent = 4

	" Open MiniBufExplorer as a sidebar more like I got used to with Kate
	let g:miniBufExplVSplit=25
	let g:miniBufExplorerMoreThanOne=9999
	let g:miniBufExplCloseOnSelect = 1
	let g:miniBufExplToggleRefocuses = 1
	"let g:miniBufExplUseSingleClick = 1
	"let g:miniBufExplForceSyntaxEnable = 1

	" Make sure NERDTree always opens with the right dimensions
	let NERDTreeQuitOnOpen = 1
	let NERDTreeWinSize = 30

	" Show a jump list automatically on save if errors are found
	let g:syntastic_auto_loc_list = 1

	" Things to double-check the efficacy of:
	let python_highlight_all = 1
	let g:PHP_default_indenting = 1

	" Set up Conque to match my workflow better
	let g:ConqueTerm_CWInsert = 1
	let g:ConqueTerm_InsertOnEnter = 1
endif


" }}}
" {{{ Load Plugin Bundles

" Explicitly disable filetype-specific features before loading pathogen in case
" we're on a Debian-based distro. (To force a rescan when re-enabled)
if exists("+filetype")
	filetype off
endif

" Use Pathogen to handle vim plugins as bundles
call pathogen#runtime_append_all_bundles()

" Enable all filetype-specific features
if exists("+filetype")
	filetype plugin indent on
endif

" }}}
" {{{ Define Autocommands

" Enable the syntax-based fallback for omni-completion
if has("autocmd") && exists("+omnifunc")
	autocmd Filetype * if &omnifunc == "" | setlocal omnifunc=syntaxcomplete#Complete | endif
endif

" Filetype-specific autocommands
if has("autocmd") && exists("+filetype")
	if exists(":DetectIndent")
		" Run the DetectIndent plugin automatically
		autocmd BufReadPost * :DetectIndent
	endif

	" Automatically strip trailing whitespace from lines when saving non-M4 files.
	autocmd BufWritePre * if index(['m4', 'diff', 'make', 'mail'], &ft) < 0 | exe 'normal m`' | %s/\s\+$//e | exe 'normal ``' | endif

	" Make sure that I don't accidentally cause myself problems with Makefiles
	" TODO: Make absolutely sure this overrides my call to DetectIndent
	autocmd FileType make set noexpandtab

	" Support the jQuery syntax extension from
	" http://www.vim.org/scripts/script.php?script_id=2416
	autocmd BufRead,BufNewFile *.js set filetype=javascript syntax=jquery

	" Fix a few apparent oversights in filetype detection
	autocmd BufNewFile,BufRead SCons* set syntax=python
	autocmd BufNewFile,BufRead *.mako set filetype=mako
	" ...and work around a sudoedit-vim interaction quirk
	autocmd BufNewFile,BufRead *.ebuild.* set filetype=ebuild
endif

" Work around a very annoying bug in the PHP filetype's indent profile.
" FIXME: I'm just gonna have to fix the PHP indent script. This won't do.
" autocmd FileType php filetype indent off | runtime! $VIM/vim71/indent/html.vim

" }}}
" {{{ Key Bindings

" Make Up, Down, Home, and End move in a more visually-intuitive fashion when
" dealing with soft-wrapped text. g0 and g$ are unacceptable. I use these
" motions far too often (and far too intuitively) to use two-character commands
" where one of them involves a shifted character. As for j and k, they're just
" too alien to my muscle memory.
map <up> gk
map <down> gj
map <home> g<home>
map <end> g<end>
imap <up> <C-o>gk
imap <down> <C-o>gj
imap <home> <C-o>g<home>
imap <end> <C-o>g<end>

" Set up Ctrl-N Ctrl-N to toggle the line numbers column.
nmap <C-N><C-N> :set invnumber<CR>

" Set up Ctrl-L to turn off search result highlights.
noremap <c-l> :nohls<CR><c-l>

" Provide a convenient, concise way to work beyond single files
map <unique> <Leader>p :SessionList<CR>
map <unique> <Leader>s :SessionSave<CR>
map <unique> <Leader>nt :NERDTreeToggle<CR>
map <unique> <Leader>[ :NERDTreeToggle<CR>
map <unique> <Leader>] :TMiniBufExplorer<CR>

" }}}
" {{{ Command: Git Grep (:G)
" http://vim.wikia.com/wiki/Git_grep
" TODO: Figure out how to make this open as a jump/quickfix list pane
func GitGrep(...)
  let save = &grepprg
  set grepprg=git\ grep\ -n\ $*
  let s = 'grep'
  for i in a:000
    let s = s . ' ' . i
  endfor
  exe s
  let &grepprg = save
endfun
command -nargs=? G call GitGrep(<f-args>)

" 'Ctrl+X G' to run GitGrep on the word under the cursor
func GitGrepWord()
  normal! "zyiw
  call GitGrep('-w -e ', getreg('z'))
endf
nmap <C-x>G :call GitGrepWord()<CR>
" }}}
" vim:ft=vim:fdm=marker:ff=unix:noexpandtab
