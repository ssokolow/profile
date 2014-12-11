" Stephan Sokolow's .vimrc (WIP)
" If you are unfamiliar with vim's folding commands, type zR.

" {{{ Quick Reference
"
"  TODO: Decide what to do with *this* quick reference:
"        https://cdn.shopify.com/s/files/1/0165/4168/files/preview.png
"
"  NOTE: See ":help \%V" for forcing a regex to match what was actually
"        selected in visual mode.
"
"  :e {file}    Edit {file} in new buffer
"  :ene         Edit new (empty) file in new buffer
"
"  :tabe {file} Edit {file} in new tab
"  :tabnew      Edit new (empty) file in new tab
"
"  gt           Go to next tab
"  gT           Go to previous tab
"
"  ZZ           Write changes and quit (alias for :wq)
"  ZQ           Quit, discarding changes (alias for :q!)
"
" External Commands:
"   !{command}   Filter specified lines using {command}
"  :!{command}   Run {command}
"
"   <F5>         Inject the selected line(s) in a Conque REPL
"   <F6>         Inject the current file into a Conque REPL
"   <F7>         Run the current file via its shebang
"
"  :sh           Open a shell (hides Vim until exited)
"   \C           Open the shell in a :split console
"
"   <F9>         Send selected text to :split console
"   <F10>        Send current buffer to :split console
"   <F11>        Toggle editability of :split console as a buffer
"
"   TODO:
"   - Figure out the command for "open current path in {command}"
"
" File Navigation And Management:
"  \s           Save Current Session
"  \p           Open Session Manager
"  \[           Toggle NERDTree
"  \]           Toggle MiniBufExplorer
"
"  :Rename      Rename file attached to the current buffer
"
"  <C-6>        Cycle between most recent two buffers
"  <C-^>          "      "     "      "    "     "
"  :A           Switch between source and header file
"
"  :AS/:AV      Split horiz/vert and switch to matching source/header
"  :find {X}    Find file {X} and edit it.
"  :sf {X}      Find file {X} and edit it in a new :split.
"  gf           Find file named under cursor and edit it.
"
"  \g           Go to definition of token under cursor
"  <C-]>        Jump to tag under cursor.
"  <C-T>        Undo the most recent jump to tag.
"
"  [o           Open previous file in the directory. (alphabetically)
"  ]o           Open next file in the directory. (alphabetically)
"
"  :G           'git grep' on the provided string
"  <C-X> G      'git grep' on the word under the cursor
"
"  :e ++enc=<encoding>
"               Reload the file, interpreting it as a different encoding
"
"  NERD Tree:
"   m           Display actions menu for selected entry
"
" TODO: Add relevant jedi-vim keybindings here
"       (https://github.com/davidhalter/jedi-vim)
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
"  [m/]m        Jump to start of previous/next method/class/fold
"  [M/]M        Jump to end of previous/next method/class/fold
"
"  [s/]s        Jump to previous/next misspelled word
"
"  <C-o>        Pop cursor position stack (great alternative to marks)
"
" Folds:
"  zo/zc       Open/Close fold
"  zO/zC       Open/Close fold and all child folds
"  zr/zm       Reduced/More folding (open/close one level of folds)
"  zR/zM       Open/Close all folds
"
" Marks: (Tip: Marks are global. You can use them to switch buffers.)
"  m{a-zA-Z}   Set mark
"  `{mark}     Jump to mark
"  '{mark}     Jump to first non-blank character on marked line
"  `.          Jump to position of last edit (Good for recovering from 'peek-scrolling')
"
"  :marks      List currently-set marks
"
"  Mark Types:
"   a - z    Local marks (unique to each file)
"   A - Z    Global marks (let you jump between files)
"   0 - 9    Last position of the cursor {#} sessions ago
"   [   ]    First/Last character of previously yanked text
"   <   >    First/Last character of most recent Visual-mode selection
"
" Paste Registers:
"   ".       Last inserted text
"   "%       Name of file in current buffer
"   "#       Name of file in previous buffer
"   "*       X11 SELECTION buffer
"   "+       X11 CLIPBOARD buffer
"   "~       Contents of last drag-and-drop (Keybind <Drop> to catch the event)
"   "/       Last search pattern
"
"  TODO: Find or set insert-mode bindings for moving and deleting word-by-word
"
" Noteworthy Motions:
"  i {char}     Everything in paired {char} centered on cursor (operator req'd)
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
"  Within Line Only:
"   f/F {char}   Move forward/back onto [count]'th occurrence of {char}
"   t/T {char}   Move forward/back 'til before/after [count]'th occurrence of {char}
"   ;/,          Repeat previous same/opposite f/t/F/T motion [count] times.
"
"  For CUA Arrow Key Junkies:
"   h/j/k/l      Left/Down/Up/Right (Character/Linewise)
"   gj/gk        Down/Up (Visually)
"   g<Home/End>  Home/End (Visually)
"
"  In Python Code:
"   <C-c> d      Show documentation for token under cursor
"   <C-c> g      Go to definition of token under cursor
"   <C-c> f      Find occurrences of token under cursor
"
" Editing:
"  <C-V>        Visual Block mode (A.K.A. column mode)
"
"  <C-A>/<C-X>  Increment/decrement number/date/time/numeral under cursor.
"               (Also supports letters of the alphabet in visual mode)
"
"  \c           Trigger snippet expansion
"  \u           Toggle undo history browser
"
"  \c<Space>    Toggle comment state for selected lines
"  \cy          Yank then comment selected lines
"  \cc          Comment selected lines
"  \cl          Comment selected lines (aligned)
"  \cu          Uncomment selected lines
"  \cA          Begin end-of-line comment
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
"  zf           Create fold (Adds markers around selection if foldmethod=marker)
"  zg/zG        Add word to spellcheck's permanent/session whitelist
"  z=           Get suggested spelling corrections for word under cursor
"
"  gg=G         Reindent the entire file according to the current indent setup
"               (Assuming 'equalprg' hasn't redefined the meaning of =)
"
"  :g/re/p      Print (list) all lines matching re (or any regex)
"  :g/re/d      Delete all lines matching re
"  :v/re/d      Delete all lines NOT matching re
"
"  :sort        Sort lines
"  :sort!       Sort lines in reverse
"  :sort u      Sort lines, discarding duplicates
"  :sort n      Sort lines numerically rather than lexicographically
"               (http://vim.wikia.com/wiki/Sort_lines)
"
"  :Loremipsum [word count]
"               Insert placeholder text
"
"  In Python Code:
"    :Rope*     Various commands which allow batch refactoring
"
"  Insert Mode:
"   Tab          Indent/Snippets/Omni-Completion (Smart)
"   <C-P>        Omni-Completion (when Smart isn't smart enough)
"
"   <C-V>        Type the following character literally
"
"   <C-X> /      Close the last open HTML/PHP/Django/eRuby tag
"   <C-X> Space  Create tag pair from the typed word (single line)
"   <C-X> Enter  Create tag pair from the typed word (multi-line)
"
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
"   Insert Mode:
"    <C-S>X Insert paired X and position the cursor in between
"
"  Vis:
"   Use visual mode to select and then...
"    :B {cmd}   Apply an editor command to selected region
"    :S {pat}   Search only selected region
"
" Display Control:
"  [count] <C-W> +/-/</> Resize the current pane
"  <C-W> _    Maximize current pane
"  <C-W> =    Make all panes equal size
"  <C-W> r/R  Rotate pane positions to the right/left.
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
" - My quick reference is half for me and half for anyone reading this, so it's
"   thorough but well-organized and I omit obvious stuff like :w unless it's for
"   comparison or I use it infrequently.
" }}}
" {{{ TODO:
" * Make better use of UltiSnips's advanced syntax
" * http://vim.sourceforge.net/scripts/script.php?script_id=301 (xmledit)
" * http://constantcoding.blogspot.ca/2013/07/quick-vim-trick-for-fixing-indentation.html"
" * Django:
"   * https://github.com/chronossc/my-vim-confs/blob/master/.vimrc
"     (http://chronosbox.org/blog/read-to-work-vim-confs-for-python-and-django)
"   * http://stackoverflow.com/questions/5078592/configuring-django-snipmate-snippets-only-for-django-projects
"   * Set up the Python side of https://github.com/robhudson/snipmate_for_django
"   * Figure out how to prevent Omni-completion for Python from being so slow.
"   * https://code.djangoproject.com/wiki/UsingVimWithDjango
"   * http://blog.fluther.com/django-vim/ (Omni-completion)
"   * http://rope.sourceforge.net/ropevim.html (Refactoring)
" * Folding:
"   * A newly created fold shouldn't start collapsed. (PitA with fdm=indent)
"   * Figure out how to use find and folding together so find doesn't open all
"     my folds and then leave them opened.
" * Fix the DetectIndent problem with tripping over /*\n*\n*\n*/
" * Decide whether to use PyChecker or PyLint for Python :make
" * Find or write a script which strips the former next line's indenting when
"   I remove a newline character with the Delete key.
" * Set up some concise prev/next tab keybindings
" * Choose a different color scheme for the ncurses omni-completion popup
" * Decide how I want NERDTree to behave relative to cd.
" * Set up and memorize a suitable set of snipMate snippets.
" * Set up syntastic linting for CSS
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
" * Explore alternate Vim color schemes.
" * also :h function-list   if you ever want to see what else is available
" ----
" * http://vim.wikia.com/wiki/Integration_with_PyUnit_testing_framework
" * http://www.vim.org/scripts/script.php?script_id=974
" * http://vim.wikia.com/wiki/GNU_Screen_integration
" * http://www.vim.org/scripts/script.php?script_id=3010
" * http://vim.wikia.com/wiki/Switch_between_Vim_window_splits_easily
" * http://vim.runpaint.org/navigation/bookmarking-lines-with-visible-markers/
" * http://www.vim.org/scripts/script_search_results.php?keywords=php+indent&script_type=&order_by=rating&direction=descending&search=search
" * http://stackoverflow.com/questions/313359/annoying-vim-unindent-rules
" * Look into merging tag_signature.vim with
"   http://vim.wikia.com/wiki/Use_balloonexpr_effectively
" ----
" * http://vimdoc.sourceforge.net/htmldoc/quickfix.html#quickfix
" * http://vimdoc.sourceforge.net/htmldoc/motion.html#operator
" * http://vimdoc.sourceforge.net/htmldoc/quickfix.html#errorformat

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

set nocompatible | filetype indent plugin on | syn on
set modeline
set hidden

" It seems Ubuntu's defaults are less agreeable than Gentoo's.
set nobackup
set nowritebackup

" Stuff that gVimPortable revealed to be necessary
set enc=utf-8

" I don't like my apps bugging me about donations or flooding me with recover
" alerts when I restore a session. If I need to recover, I'll do it manually.
" TODO: Figure out how to reimplement "still running" warnings manually.
set shortmess+=IA

" Don't treat word-wrapped lines as an 'all or nothing' thing when displaying.
set display+=lastline
set scrolloff=2 " I like to have a two-line 'preview' when scrolling

" I want a decent status line
set showcmd     " Show in-progress commands so I can figure out what the heck I accidentally hit.

" Make tabs and trailing whitespace visible
set list
set listchars=tab:»·,trail:· " show tabs and trailing spaces

" Only word-wrap comments and word-wrap them at 79 characters.
set formatoptions-=t     " No word-wrap inside code.
set formatoptions+=croql " Make the behaviour I'm used to explicit
set textwidth=79

" I prefer 4-space indentation by default but use expected 8-space tabs
set expandtab
set tabstop=8
set softtabstop=4
set shiftwidth=4

" Put swapfiles all together in one of the system temporary directories so it's
" easy for me to flush them if need be.
" (And don't let them clutter up my ~/tmp)
" TODO: Can I do this on one line?
set dir-=.,~/tmp

" TODO: Get these cooperating. (n seems to require t)
"set formatoptions+=n
"set formatlistpat="^\s*\(\d\+[\]:.)}\t ]\|[-*]\)\s*"

" Make my saved views portable and rely on modeline for saving options
set viewoptions=cursor,folds,slash,unix

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

" Let's default to indent-based folding since it's the most automatic
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
    set wildignore+=*.pyc,*.pyo,*.class
else
    set suffixes+=.pyc,.pyo,.class
endif

" Use 'ack' as my grep program since it's more comfortable for me
" (In a Debian-compatible way)
if executable("ack-grep")
    set grepprg=ack\ -a
elseif executable("ack")
    set grepprg=ack\ -a
endif

" }}}
" {{{ Configuration (Plugins)
if exists(":let")
    " Fix an incompatibility with Lubuntu Precise
    " TODO: Remove this once I've upgraded to ack 2.x
    let g:ack_default_options = " -H --nocolor --nogroup --column"

    " Set up Conque to match my workflow better
    let g:ConqueTerm_CWInsert = 1
    let g:ConqueTerm_InsertOnEnter = 1


    " I prefer 4-char space indentation as my default for DetectIndent too
    let g:detectindent_preferred_expandtab = 1
    let g:detectindent_preferred_indent = 4

    " Make YouCompleteMe auto-dismiss the scratch buffer showing a function's
    " definition.
    let g:ycm_autoclose_preview_window_after_completion=1

    " Open MiniBufExplorer as a sidebar more like I got used to with Kate
    let g:miniBufExplVSplit=25
    let g:miniBufExplorerAutoStart = 0
    let g:miniBufExplUseSingleClick = 1
    let g:miniBufExplCloseOnSelect = 1

    " Make sure NERDTree always opens with the right dimensions
    let NERDTreeQuitOnOpen = 1
    let NERDTreeWinSize = 30


    " TODO: Things to double-check the efficacy of:
    let python_highlight_all = 1
    let g:pcs_check_when_saving = 1

    let g:ragtag_global_maps = 1

    " Use a more intuitive symbol to denote changed lines
    let g:signify_sign_change = '~'

    " Configure automatic syntax and style checks
    let g:syntastic_check_on_open = 1
    let g:syntastic_auto_loc_list = 1

    " Use \c for to trigger snippet expansion since YouCompleteMe
    " already uses Tab for cycling through the completions menu.
    let g:UltiSnipsExpandTrigger="<Leader>c"
    let g:UltiSnipsJumpForwardTrigger="<tab>"
    let g:UltiSnipsJumpBackwardTrigger="<s-tab>"

    " --= Vala highlighting settings (https://live.gnome.org/Vala/Vim) =--
    " Enable comment strings
    let vala_comment_strings = 1
    " Highlight space errors
    let vala_space_errors = 1
endif


" }}}
" {{{ Bootstrap VAM (vim-addon-manager)

" See vim-addon-manager-getting-started for commented version.

fun! EnsureVamIsOnDisk(plugin_root_dir)
  " windows users may want to use http://mawercer.de/~marc/vam/index.php
  " to fetch VAM, VAM-known-repositories and the listed plugins
  " without having to install curl, 7-zip and git tools first
  " -> BUG [4] (git-less installation)
  let vam_autoload_dir = a:plugin_root_dir.'/vim-addon-manager/autoload'
  if isdirectory(vam_autoload_dir)
    return 1
  else
    if 1 == confirm("Clone VAM into ".a:plugin_root_dir."?","&Y\n&N")
      call mkdir(a:plugin_root_dir, 'p')
      execute '!git clone --depth=1 git://github.com/MarcWeber/vim-addon-manager '.
               \       shellescape(a:plugin_root_dir, 1).'/vim-addon-manager'
      " VAM runs helptags automatically when you install or update plugins
      exec 'helptags '.fnameescape(a:plugin_root_dir.'/vim-addon-manager/doc')
    endif
    return isdirectory(vam_autoload_dir)
  endif
endfun

fun! SetupVAM()
  " Set advanced options like this:
  " let g:vim_addon_manager = {}
  " let g:vim_addon_manager.key = value
  "     Pipe all output into a buffer which gets written to disk
  " let g:vim_addon_manager.log_to_buf =1

  " Example: drop git sources unless git is in PATH. Same plugins can
  " be installed from www.vim.org. Lookup MergeSources to get more control
  " let g:vim_addon_manager.drop_git_sources = !executable('git')
  " let g:vim_addon_manager.debug_activation = 1

  " VAM install location:
  let c = get(g:, 'vim_addon_manager', {})
  let g:vim_addon_manager = c
  let c.plugin_root_dir = expand('$HOME/.vim/vim-addons', 1)
  if !EnsureVamIsOnDisk(c.plugin_root_dir)
    echohl ErrorMsg | echomsg "No VAM found!" | echohl NONE
    return
  endif
  let &rtp.=(empty(&rtp)?'':',').c.plugin_root_dir.'/vim-addon-manager'

  " Tell VAM which plugins to fetch & load:
  call vam#ActivateAddons([], {'auto_install' : 0})

  " How to find addon names?
  " - look up source from pool
  " - (<c-x><c-p> complete plugin names):
  " You can use name rewritings to point to sources:
  "    ..ActivateAddons(["github:foo", .. => github://foo/vim-addon-foo
  "    ..ActivateAddons(["github:user/repo", .. => github://user/repo
  " Also see section "2.2. names of addons and addon sources" in VAM's documentation
endfun
call SetupVAM()

" }}}
" {{{ Load Plugin Bundles

" Basic IDE functionality
VAMActivate Syntastic                   " Syntax check on save
VAMActivate YouCompleteMe               " Smart Competion
VAMActivate ragtag surround matchit.zip " Editing aid for XML and HTML
VAMActivate UltiSnips vim-snippets      " Code Snippets
VAMActivate bwHomeEndAdv                " Smart Home/End

" Ack support (Must come before The_NERD_tree)
VAMActivate ack nerdtree-ack

" Basic Project Functionality
VAMActivate sessionman                     " Session manager
VAMActivate minibufexplorer                " Vim buffer sidebar
VAMActivate The_NERD_tree nerdtree-execute " Filesystem sidebar

" Supplemental IDE Functionality
VAMActivate rename%4840              " Rename command for the file being edited
VAMActivate The_NERD_Commenter       " Comment/Uncomment commands
VAMActivate Conque_Shell conque-repl " Embedded shell and REPL

" Autodetection
VAMActivate DetectIndent            " File's indent settings
VAMActivate NERD_tree_Project       " Root project folder for current file

" Make sure I can't lose anything by accident while using undo
VAMActivate Gundo
nnoremap <Leader>u :GundoToggle<CR>

" More Vim Commands
VAMActivate loremipsum unimpaired vis VisIncr

" Git integration
VAMActivate fugitive vim-signify

" -- TODO: Tune and sort --
VAMActivate LargeFile

" TODO: Make this conditional on Python files
VAMActivate indentpython%974
VAMActivate github:jmcantrell/vim-virtualenv

" TODO: Make this conditional on CoffeeScript files
VAMActivate vim-coffee-script

" TODO: Figure out how to rebuild my statusline using airline
"VAMActivate  vim-airline
"let g:airline#extensions#syntastic#enabled = 0
"let g:airline#extensions#virtualenv#enabled = 1

"if has('gui_running')
"    let g:airline_powerline_fonts = 1
"else
"    if !exists('g:airline_symbols')
"        let g:airline_symbols = {}
"    endif

"    let g:airline_left_sep = '▶'
"    let g:airline_right_sep = '◀'
"endif

" }}}

" {{{ Set the color scheme
colorscheme default_256_fixed

if !has('gui_running')
    " Color scheme editor via `:help hicolors`
    "VAMActivate HiColors

    " Other theme-improvement tools:
    " http://www.vim.org/scripts/script.php?script_id=1488
    " http://bytefluent.com/vivify/
    " http://www.vimtax.com/
    " http://cocopon.me/app/vim-color-gallery/
    " https://code.google.com/p/vimcolorschemetest/
    " http://vim.sourceforge.net/scripts/script.php?script_id=625

    " Mechanism for loading GUI color schemes in 256-color terminals
    "VAMActivate guicolorscheme
    "GuiColorScheme sublime
endif
" }}}
" {{{ Define Autocommands

" Save folding status automatically
"if has("autocmd")
"    autocmd BufWinLeave ?* silent mkview
"    autocmd BufWinEnter ?* silent loadview
"endif

" Run the DetectIndent plugin automatically
if has("autocmd")
    autocmd BufReadPost * :DetectIndent
endif

" Filetype-specific autocommands
if has("autocmd") && exists("+filetype")
    " Automatically strip trailing whitespace from lines when saving non-M4 files.
    " Also, exclude SQL because I often have check constraints which this would
    " mangle.
    autocmd BufWritePre * if index(['m4', 'diff', 'make', 'mail', 'sql'], &ft) < 0 | exe 'normal m`' | %s/\s\+$//e | exe 'normal ``' | endif

    " Make sure that I don't accidentally cause myself problems with Makefiles
    " TODO: Make absolutely sure this overrides my call to DetectIndent
    autocmd FileType make set noexpandtab

    " Autocomplete </ for closing tags in HTML/XML files
    " TODO: Why isn't this working as I expect?
    autocmd FileType html,xml,xsl iabbrev <buffer> </ </

    " Hook up :make to preview GraphViz dot rendering
    autocmd FileType dot set makeprg=dot\ %\ -Tpng\ -o\ %.png;\ display\ %

    " Set up an 'escpos' filetype which makes the width of my thermal printer's
    " paper clear and sets up :make to print things.
    autocmd FileType escpos set colorcolumn=32
    autocmd FileType escpos set makeprg=~/bin/escpos-cli.py\ print\ %
    autocmd BufNewFile,BufRead *.escpos set filetype=escpos

    " Hook up syntax/tiddlywiki.vim
    autocmd BufNewFile,BufRead *.tid set filetype=tiddlywiki
    " Support the jQuery syntax extension from
    " http://www.vim.org/scripts/script.php?script_id=2416
    autocmd BufRead,BufNewFile *.js set filetype=javascript syntax=jquery
    autocmd BufRead,BufNewFile *.jsm set filetype=javascript syntax=jquery

    " ...and work around a sudoedit-vim interaction quirk
    autocmd BufNewFile,BufRead *.ebuild.* set filetype=ebuild

    " ...and treat .md as Markdown, not Modula2
    autocmd BufNewFile,BufRead *.md set filetype=markdown

    " Use the indentation CoffeeLint defaults to. It makes sense.
    autocmd FileType coffee set shiftwidth=2 softtabstop=2

    augroup python
        au!
        " Set indent fold for Python files since foldmethod=syntax does nothing
        autocmd FileType python set foldmethod=indent
        autocmd FileType python set foldlevel=99

        " Make gf search installed Python modules
        autocmd FileType python set path+=/usr/lib/python2.7/**,

        " Until I think of something better, enable Django snips for all Python
        autocmd FileType python set ft=python.django

        " Fix a few apparent oversights in filetype detection
        autocmd BufNewFile,BufRead SCons* set syntax=python
        autocmd BufNewFile,BufRead *.mako set filetype=mako
        autocmd BufNewFile,BufRead *.django set filetype=htmldjango

        " Add GMPL (GNU Linear Programming Kit) support
        autocmd BufNewFile,BufRead *.mod set filetype=gmpl
    augroup END

    augroup vala
        au!
        au FileType vala setlocal smartindent
        au BufRead *.vala,*.vapi set efm=%f:%l.%c-%[%^:]%#:\ %t%[%^:]%#:\ %m
        au BufRead,BufNewFile *.vala,*.vapi setfiletype vala
    augroup END

    augroup genie
        au!
        au BufNewFile *.gs setlocal filetype="genie"
        au BufRead *.gs setlocal filetype="genie"
    augroup END

    " Work around a very annoying bug in the PHP filetype's indent profile.
    " FIXME: I'm just gonna have to fix the PHP indent script. This won't do.
    " autocmd FileType php filetype indent off | runtime! $VIM/vim71/indent/html.vim

endif

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
map <unique> <Leader>C :exe "silent ConqueTermSplit " . &shell<CR>
map <unique> <Leader>p :SessionList<CR>
map <unique> <Leader>s :SessionSave<CR>
map <unique> <Leader>nt :NERDTreeToggle<CR>
map <unique> <Leader>[ :NERDTreeToggle<CR>
map <unique> <Leader>] :MBEToggle<CR>:MBEFocus<CR>

" Source: http://bairuidahu.deviantart.com/art/Flying-vs-Cycling-261641977
nnoremap <leader>l :ls<CR>:b<space>

" Source: https://blog.dbrgn.ch/2013/5/27/using-jedi-with-ymc/
nnoremap <leader>g :YcmCompleter GoToDefinitionElseDeclaration<CR>

" }}}
" {{{ Custom command aliases

" Alias :E as a shorter :tabe that accepts wildcards
:command -nargs=+ -complete=file E args <args><bar>argdo tabe

" Alias <Leader>qcl as a way to quickly prepare Pidgin chat logs to be quoted
" in TiddlyWiki
nnoremap <Leader>qcl :%s/\((\(\d\{2}:\)\{2}\d\{2})\) \(\S\{1,}\)/''\1 \3''/<CR>

" }}}
" {{{ Aliases to work around "physical race conditions" on some keyboards

" On keyboards which take more prssure for keys to register, when I type :
" quickly, I sometimes don't release Shift fast enough.
com! Q q
com! W w
com! Wq wq

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
" {{{ Command: Diff Unsaved Changes (:DiffSaved)
" http://vim.wikia.com/wiki/Diff_current_buffer_and_the_original_file
" (Use :diffoff to leave diff mode)
"
" Plain alternative:
"   :w !diff % -
"
function! s:DiffWithSaved()
  let filetype=&ft
  diffthis
  vnew | r # | normal! 1Gdd
  diffthis
  exe "setlocal bt=nofile bh=wipe nobl noswf ro ft=" . filetype
endfunction
com! DiffSaved call s:DiffWithSaved()
" }}}
" {{{ Shortcut: F7 = Run anything with a shebang
" Source: http://superuser.com/a/21503/48014
if has("autocmd")
    au BufEnter * if match( getline(1) , '^\#!') == 0 |
    \ execute("let b:interpreter = getline(1)[2:]") |
    \endif

    fun! CallInterpreter()
        if exists("b:interpreter")
             exec ("!".b:interpreter." %")
        endif
    endfun

    map <F7> :call CallInterpreter()<CR>
endif
" }}}
" vim:ft=vim:fdm=marker:ff=unix
