let b:ale_lint_on_save = 0  " Don't let it block the Cargo lock at inopportune times
let b:ale_linters = ['analyzer']
let b:ale_fixers = ['rustfmt', 'trim_whitespace', 'remove_trailing_lines']
let g:ale_rust_cargo_use_clippy = executable('cargo-clippy')
let g:ale_rust_rls_config = {
      \   'rust': {
      \     'clippy_preference': executable('cargo-clippy') ? 'on' : 'off'
      \   }
      \ }
let g:ale_rust_analyzer_config = {
      \ 'procMacro': { 'enable': v:true },
      \ 'diagnostics': { 'disabled': ['inactive-code', 'macro-error', 'unresolved-import', 'unresolved-proc-macro'] },
      \ }

" ---- Set up information for F7 and :make ----
let b:cargo_root_dir = fnamemodify(findfile('Cargo.toml', expand('%:p:h') . ';'), ':p:h')
if filereadable(b:cargo_root_dir . '/justfile')
    setlocal makeprg=just
    let b:f6_test_cmd = 'just test --'
    let b:f7_run_cmd = 'just run --'
elseif filereadable(b:cargo_root_dir . '/Cargo.toml')
    setlocal makeprg=cargo
    let b:f6_test_cmd = 'cargo test --'
    let b:f7_run_cmd = 'cargo run --'
endif

" ---- Adjust for Rust-spec'd maximum line length ----
setlocal textwidth=100

if has('gui_running') && &columns < 102
    set columns=102
endif
