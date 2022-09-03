
" Set indent fold for Python files since foldmethod=syntax does nothing
setlocal foldnestmax=3
setlocal foldmethod=indent

" TODO: Decide whether to just get rid of folding as "not my thing"
"setlocal foldlevel=0
setlocal foldlevel=99

" Make gf search installed Python modules
" TODO: Find a way to set this based on the shebang
" DISABLED: Seem to slow down Ctrl+P
" setlocal path+=/usr/lib/python3.5/**,

let g:ale_python_pylint_executable = 'python3'
let g:ale_python_pylint_options = '-m pylint'
" The virtualenv detection needs to be disabled.
let g:ale_python_pylint_use_global = 0

" Exclude vulture. It's too heavy to be run automatically.
" Make bandit conditional on small files.
" Make Pylint conditional on small or medium files
" Exclude PyLS because it gets buggy if you only lint on save
" NOTE: autopep8 breaks the walrus operator on *buntu 20.04 LTS
let b:fsize_scratch = getfsize(expand(@%))
if b:fsize_scratch <= 65535
    let b:ale_linters = ['flake8', 'mypy', 'pylint', 'bandit']
    let b:ale_fixers = ['autopep8', 'remove_trailing_lines', 'trim_whitespace']
elseif b:fsize_scratch <= 131072
    let b:ale_linters = ['flake8', 'mypy', 'pylint']
    let b:ale_fixers = ['autopep8', 'remove_trailing_lines', 'trim_whitespace']
else
    let b:ale_linters = ['flake8', 'mypy']
    let b:ale_fixers = ['autopep8', 'remove_trailing_lines', 'trim_whitespace']
endif

" TODO: Once I've got Python 3.6, try making it choose Pyre over MyPy when
"       available for more performant type-checking.

" E301 is disabled because it causes autopep8 to insert a blank line between
"   a `class` line and the docstring.
" E2600000000 is a non-existent error code that begins with E26 and, thus,
"   somehow prevents a bug in autopep8 0.9.1 from mangling the comments in
"   commented-out code.
let g:ale_python_flake8_executable = 'python3'
let g:ale_python_flake8_options = '-m flake8 --ignore=N802,E126,E128,E301,E401,E402'
let b:ale_python_autopep8_options = '--ignore=N802,E126,E128,E301,E401,E402,E2600000000'

" Let flake8 handle style, since it actually listens to my ignores
let b:ale_python_pyls_config = {
\   'pyls': {
\     'plugins': {
\       'pycodestyle': {
\         'enabled': v:false
\       }
\     }
\   },
\ }
