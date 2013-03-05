" Vim syntax file
" Language:     GMPL (GNU Linear Programming Kit)
" Maintainers:  Stephan Sokolow <http://www.ssokolow.com/ContactMe>
" Last Change:  2013-03-04
" Filenames:    *.mod
"
" TODO: Make this stricter to catch errors
"
" REFERENCES:
" [1] file:///usr/share/doc/glpk-doc/gmpl.pdf

if exists("b:current_syntax")
    finish
endif

let s:cpo_save = &cpo
set cpo&vim

syn case match

"
" Coding model
syn match   gmplSymbolicName    "\h\w*" contained
syn match   gmplNumericLiteral  "\(\m\d*\.\?\d\+\|\d+\.\?\)\([eE][-+]\d\+\)\?"
syn region  gmplStringSingle start=+'+ skip=+''+ end=+'+
syn region  gmplStringDouble start=+"+ skip=+""+ end=+"+
syn keyword gmplReservedKeyword and by cross diff div else if in inter less
syn keyword gmplReservedKeyword mod not or symdiff then union within

" TODO: Make it show as an error to use a reserved keyword where a symbolic
"       name is expected.

" TODO: Delimiter definition here

"
" Comment (coding model)
syn region  gmplComment  start="/\*" end="\*/" contains=gmplTodo,@Spell
syn match   gmplComment  "#.*$" contains=gmplTodo,@Spell
syn keyword gmplTodo     FIXME NOTE NOTES TODO XXX contained

"
" Statements
syn match gmplConstraintStatement "s\.t\." nextgroup=gmplSymbolicName skipwhite
syn match gmplObjectiveStatement "\(min\|max\)imize" nextgroup=gmplSymbolicName skipwhite

" --== Stuff done by sight rather than by gmpl.pdf ==--

syn keyword gmplDefStatement set param var nextgroup=gmplSymbolicName skipWhite
syn keyword gmplSectionStatement data end
syn match   gmplOperator ":="

"TODO: Figure out how to define this without conflicting with multi-line comments
syn match   gmplOperator "\m\b[-+*/^]\b"


hi def link gmplSymbolicName    Identifier     "
hi def link gmplNumericLiteral  Number         " 2.2
hi def link gmplStringSingle    String         " 2.3
hi def link gmplStringDouble    String         " 2.3
hi def link gmplReservedKeyword Keyword        " 2.4
hi def link gmplComment         Comment        " 2.6
hi def link gmplTodo            Todo
hi def link gmplConstraintStatement Statement  " 4.4
hi def link gmplObjectiveStatement Statement   " 4.5

hi def link gmplDefStatement Statement
hi def link gmplSectionStatement Statement
hi def link gmplOperator     Operator

let b:current_syntax = "gmpl"

let &cpo = s:cpo_save
unlet s:cpo_save

" vim: ts=8

