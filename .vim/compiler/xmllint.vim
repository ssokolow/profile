" Vim compiler file
" Compiler:	xmllint
" Maintainer:	Doug Kearns <djkea2@gus.gscit.monash.edu.au>
" URL:		http://gus.gscit.monash.edu.au/~djkea2/vim/compiler/xmllint.vim
" Last Change:	2004 Nov 27

if exists("current_compiler")
  finish
endif
let current_compiler = "xmllint"

if exists(":CompilerSet") != 2		" older Vim always used :setlocal
  command -nargs=* CompilerSet setlocal <args>
endif

let s:cpo_save = &cpo
set cpo-=C

" Omit validation for now since this is going to be run on every save.
" TODO: Look for a way to just silence the "no DTD" error.
CompilerSet makeprg=xmllint\ --noout\ %
"CompilerSet makeprg=xmllint\ --valid\ --noout\ %

CompilerSet errorformat=%E%f:%l:\ error:\ %m,
		    \%W%f:%l:\ warning:\ %m,
		    \%E%f:%l:\ validity\ error:\ %m,
		    \%W%f:%l:\ validity\ warning:\ %m,
		    \%E%f:%l:\ error\ :\ %m,
		    \%W%f:%l:\ warning\ :\ %m,
		    \%E%f:%l:\ parser\ error\ :\ %m,
		    \%W%f:%l:\ parser\ warning\ :\ %m,
		    \%E%f:%l:\ validity\ error\ :\ %m,
		    \%W%f:%l:\ validity\ warning\ :\ %m,
		    \%-Z%p^,
		    \%-G%.%#
" Note: This pattern has been amended for newer xmllint versions.
" TODO: Report the needed changes to the vim guys.

let &cpo = s:cpo_save
unlet s:cpo_save
