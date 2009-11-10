" Turn on spell-checking since syntax highlighting keeps it limited to
" human-targeted text. Do it here because it doesn't look good in terminals.
set spell spelllang=en_ca

" Give myself a new and a close button on the toolbar.
amenu 1.05 ToolBar.New   :tabnew<CR>
amenu 1.35 ToolBar.Close :confirm bd<CR>

" Make the Open button also provide a new tab for the new buffer.
amenu 1.10 ToolBar.Open  :browse confirm tabe<CR>

" Set up Ctrl+F2 as a key to toggle the menubar and toolbar
map <silent> <C-F2> @=<SID>ToggleGUIBars()<cr>

" I don't like 'give us money' entries in my menus
:aunmenu Help.Orphans
:aunmenu Help.Sponsor/Register

function s:ToggleGUIBars()
	if &guioptions =~# 'T'
		set guioptions-=T
		set guioptions-=m
	else
		set guioptions+=T
		set guioptions+=m
	endif
endfunction
