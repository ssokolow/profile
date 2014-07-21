" Vim syntax file for TiddlyWiki
" Language: tiddlywiki
" Last Change: 2009-07-06 Mon 10:15 PM IST
" Maintainer: http://www.swaroopch.com
" License: http://www.apache.org/licenses/LICENSE-2.0.txt
" Reference: http://tiddlywiki.org/wiki/TiddlyWiki_Markup


""" Initial checks
" To be compatible with Vim 5.8. See `:help 44.12`
if version < 600
    syntax clear
elseif exists("b:current_syntax")
    " Quit when a (custom) syntax file was already loaded
    finish
endif


""" Patterns

" Emphasis
syn match twItalic /\/\/.\{-}\/\//
syn match twBold /''.\{-}''/
syn match twUnderline /__.\{-}__/
syn match twStrikethrough /--.\{-}--/
syn match twHighlight /@@.\{-}@@/
syn match twNoFormatting /.{{{.\{-}}}}/
syn region twNoFormatting start=/^{{{/ end=/^}}}/

" Heading
syn match twHeading /^!\+\s*.*$/

" Todo
syn keyword twTodo TODO FIXME XXX

" Comment
syn region twComment start=/\/%/ end=/%\//

" Lists
syn match twList /^[\*#]\+/

" Definition list
syn match twDefinitionListTerm /^;.\+$/
syn match twDefinitionListDescription /^:.\+$/

" Blockquotes
syn match twBlockquote /^>\+.\+$/
syn region twBlockquote start=/^<<</ end=/^<<</

" Table
syn match twTable /|/

" Link
syn region twLink start=/\[\[/ end=/\]\]/

" Raw HTML
syn region twRawHtml start=/<html>/ end=/<\/html>/


""" Highlighting

hi def twItalic term=italic cterm=italic gui=italic
hi def twBold term=bold cterm=bold gui=bold

hi def link twUnderline Underlined
hi def link twStrikethrough Ignore
hi def link twHighlight Todo
hi def link twNoFormatting Constant
hi def link twTodo Todo
hi def link twHeading Title
hi def link twComment Comment
hi def link twList Structure
hi def link twDefinitionListTerm Identifier
hi def link twDefinitionListDescription String
hi def link twBlockquote Repeat
hi def link twTable Label
hi def link twLink Typedef
hi def link twRawHtml PreProc

