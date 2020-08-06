augroup ftdetect_ssokolow
    au!

    " Work around a sudoedit-vim interaction quirk
    autocmd BufNewFile,BufRead *.ebuild.* set filetype=ebuild

    " Add an 'escpos' format for easily composing receipt printer output
    autocmd BufNewFile,BufRead *.escpos set filetype=escpos

    " Treat .md as Markdown, not Modula2
    autocmd BufNewFile,BufRead *.md set filetype=markdown

    " Set appropriate file type for SConstruct files
    autocmd BufNewFile,BufRead SCons* set filetype=python

    " Support TiddlyWiki5 .tid files
    autocmd BufNewFile,BufRead *.tid set filetype=tiddlywiki
augroup END
