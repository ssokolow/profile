" Notes on my rationale:
" - I keep Select mode off because Visual mode is more useful and I can get
"   Select-mode behaviour by just typing an extra c after selecting.
" - I've rebound the up/down arrows and home/end to take soft-wrap into account
"   because it's what I'm already used to and, in the case of home/end,
"   it'll always be a simpler motion than g0 and g$.

" TODO:
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

" Just as a reminder of how to do this.
" Originally from:
" http://the-shaolin.blogspot.com/2004/12/my-own-2-cent-vim-tip.html
" ab TODO: ssokolow :r!date +\%Y-\%m-\%dkJA TODO:
" ab FIXME: ssokolow :r!date +\%Y-\%m-\%dkJA FIXME:

set nocompatible
set modeline

" I don't like my apps to bug me about donations.
set shortmess+=I

" Set up more comfortable filesystem navigation
set wildmenu
set wildignore+=.pyc,.pyo,.class
"set suffixes+=.pyc,.pyo,.class

" Make searching more efficient
set incsearch
set hlsearch
" TODO: Consider inabling ignorecase and smartcase
" Set up Ctrl-L to turn off search result highlights.
noremap <c-l> :nohls<CR><c-l>

" I want full mouse support when using a Yakuake-->screen-->vim stack.
if exists("+mouse")
	set ttymouse=xterm2
	set mouse=a
endif

" I prefer 4-character indentation
" TODO: Should I set tabstop=8?
set tabstop=4
set softtabstop=4
set shiftwidth=4
set expandtab

" Only word-wrap comments and word-wrap them at 79 characters.
set formatoptions-=t	" No word-wrap inside code.
set textwidth=80
"set formatoptions+=can	" TODO: Get these cooperating.
"	(n seems to require t while I use c and a messes my lists)
"set formatlistpat="^\s*\(\d\+[\]:.)}\t ]\|[-*]\)\s*"

" Don't treat word-wrapped lines as an 'all or nothing' thing when displaying.
set display+=lastline
set scrolloff=2 " I like to have a two-line 'preview' when scrolling

" I want a decent status line
set showcmd      " Show in-progress commands so I can figure out what the heck I accidentally hit.

" Make tabs and trailing whitespace visible
set list
set lcs=tab:»·   "show tabs
set lcs+=trail:· "show trailing spaces

" Make my sessions a bit more like projects and less like vimrc overrides.
set sessionoptions=blank,curdir,folds,help,tabpages,resize,slash,unix,winpos,winsize

if exists("+filetype")
	" Enable all filetype-specific features
	filetype plugin indent on
endif

" Enable the syntax-based fallback for omni-completion
if has("autocmd") && exists("+omnifunc")
    autocmd Filetype * if &omnifunc == "" | setlocal omnifunc=syntaxcomplete#Complete | endif
endif

if has("autocmd") && exists("+filetype")
	" Automatically strip trailing whitespace from lines when saving non-M4 files.
	autocmd BufWritePre * if index(['m4', 'diff', 'make', 'mail'], &ft) < 0 | exe 'normal m`' | %s/\s\+$//e | exe 'normal ``' | endif

	" Set up my preferred behaviour for auto-formatting in Python.
	autocmd FileType python set expandtab
	autocmd BufReadPost SCons* set syntax=python

	" Support the jQuery syntax extension from
	" http://www.vim.org/scripts/script.php?script_id=2416
	autocmd BufRead,BufNewFile *.js set filetype=javascript.jquery

	" Fix an apparent oversight in Gentoo's configuration with regards to sudoedit
	autocmd BufNewFile,BufRead *.ebuild.* set filetype=ebuild

	" Make sure that I don't accidentally cause myself problems with Makefiles
	autocmd FileType make set noexpandtab

	" Fix the extension binding for the mako syntax plugin
	autocmd BufNewFile,BufRead *.mako set filetype=mako
endif

if exists(":let") == 2
	" TODO: Make sure this is actually working.
	let python_highlight_all = 1
endif

" Work around a very annoying bug in the PHP filetype's indent profile.
" FIXME: I'm just gonna have to fix the PHP indent script. This won't do.
" autocmd FileType php filetype indent off | runtime! $VIM/vim71/indent/html.vim

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

" Set up quick shortcuts for saving and switching sessions
nmap <C-S> :wa<Bar>exe "mksession! " . v:this_session<CR>
nmap <C-A> :wa<Bar>exe "mksession! " . v:this_session<CR>:so ~/*.vim

" Duplicate vim's Ctrl-P completion onto Ctrl-Tab
" Reminder: I've got TextMate-style completion on <Tab>
imap <C-Tab> <C-P>

" TODO: Figure out how to make this just work based on the detected language.
" set foldmethod=indent
" set foldcolumn=1

