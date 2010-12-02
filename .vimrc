" Notes on my rationale:
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

" TODO:
" * Fix the PyFlakes-quickfix integration so the quickfix lines are clickable
" * Set up some concise prev/next tab keybindings
" * Choose a different color scheme for the ncurses omni-completion popup
" * Decide how I want NERDTree to behave relative to cd.
" * Set up and memorize a suitable set of snipMate snippets.
" * Set up on-save quickfix lint for CSS
" * Figure out how to solve my disagreement with Vim over what constitutes
"   an acceptable response to existing swap files.
" * Adjust my session-saving keybinding so it asks for confirmation somehow
"   if no prior session was saved rather than dumping a Session.vim into the
"   working directory.
" ----
" * http://vim.wikia.com/wiki/Integration_with_PyUnit_testing_framework
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
" ----
" * http://vimdoc.sourceforge.net/htmldoc/quickfix.html#quickfix
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

" Stuff to build habits for:
" * http://www.catonmat.net/series/vim-plugins-you-should-know-about
" * Splitting and unsplitting:
"  - http://blogs.sourceallies.com/2009/11/vim-splits-an-introduction/
"  - http://jmcpherson.org/windows.html

" Just as a reminder of how to do this.
" Originally from:
" http://the-shaolin.blogspot.com/2004/12/my-own-2-cent-vim-tip.html
" ab TODO: ssokolow :r!date +\%Y-\%m-\%dkJA TODO:
" ab FIXME: ssokolow :r!date +\%Y-\%m-\%dkJA FIXME:

" ----==== Configuration ====----

set nocompatible
set modeline

" I don't like my apps to bug me about donations.
set shortmess+=I

" Don't treat word-wrapped lines as an 'all or nothing' thing when displaying.
set display+=lastline
set scrolloff=2 " I like to have a two-line 'preview' when scrolling

" I want a decent status line
set showcmd      " Show in-progress commands so I can figure out what the heck I accidentally hit.

" Make tabs and trailing whitespace visible
set list
set listchars=tab:»·,trail:· " show tabs and trailing spaces

" Only word-wrap comments and word-wrap them at 80 characters.
set formatoptions-=t     " No word-wrap inside code.
set formatoptions+=croql " Make the behaviour I'm used to explicit
set textwidth=80

" TODO: Get these cooperating. (n seems to require t)
"set formatoptions+=n
"set formatlistpat="^\s*\(\d\+[\]:.)}\t ]\|[-*]\)\s*"

" Make my sessions a bit more like projects and less like vimrc overrides.
set sessionoptions=blank,curdir,folds,help,resize,slash,tabpages,unix,winpos,winsize

" Use 'ack' as my grep program since it's more comfortable for me
" TODO: See if I can find a way to switch this based on whether PATH has ack
set grepprg=ack\ -a

" ----==== Configuration (Optional Vim Features) ====----

" I prefer 4-character space indentation
if exists(":let")
	let g:detectindent_preferred_expandtab = 1
	let g:detectindent_preferred_indent = 4
else
	set expandtab
	set tabstop=4
	set softtabstop=4
	set shiftwidth=4
endif

if exists(":let")
	let g:ragtag_global_maps = 1
	let g:pcs_check_when_saving = 1
	let g:SuperTabDefaultCompletionType = "context"
	let python_highlight_all = 1 " TODO: Make sure this is actually working.

	let g:checksyntax_auto_php = 1
	let g:checksyntax_auto_javascript = 1
	let g:checksyntax_auto_lua = 1
	let g:checksyntax_auto_html = 1
	"let g:checksyntax_auto_xml = 1  " TODO: Fix this so it actually recognizes errors
	" Note: The ruby checker currently calls the ruby "compiler"... do not want.
endif

" Make searching more efficient
if has("extra_search")
	set incsearch
	set hlsearch
	set ignorecase
	set smartcase
endif

if exists("+folding")
	" TODO: Figure out how to make this just work based on the detected language.
	" set foldmethod=indent
	" set foldcolumn=1
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

" ----==== Load Plugin Bundles ====----

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

" ----==== Define Autocommands ====----

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

" ----==== Key Bindings ====----

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

" Reminder: Vim's omni-completion is on C-P when it'd conflict with snipMate.

" Set up Ctrl-N Ctrl-N to toggle the line numbers column.
nmap <C-N><C-N> :set invnumber<CR>

" Set up Ctrl-L to turn off search result highlights.
noremap <c-l> :nohls<CR><c-l>

" Set up quick shortcuts for saving and switching sessions
nmap <C-S> :wa<Bar>exe "mksession! " . v:this_session<CR>
nmap <C-A> :wa<Bar>exe "mksession! " . v:this_session<CR>:so ~/*.vim

" Provide a more concise way to toggle NERDTree
map <F2> :NERDTreeToggle<CR>

