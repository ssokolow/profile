" Vim compiler file
" Compiler: Pychecker for Python
" http://vim.wikia.com/wiki/Integrate_Pylint_and_Pychecker_support
if exists("current_compiler")
  finish
endif
let current_compiler = "pychecker"
if exists(":CompilerSet") != 2 " older Vim always used :setlocal
  command -nargs=* CompilerSet setlocal <args>
endif
CompilerSet makeprg=pychecker\ %
CompilerSet efm=%f:%l:%m
