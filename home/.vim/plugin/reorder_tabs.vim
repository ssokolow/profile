" Author: Gregor Müllegger <gregor@muellegger.de>
" Version: 0.1.0
"
" Description:
"   Reorder your tabs in a simple way.
"
" Installation:
"   Put this file (reorder_tabs.vim) in your plugin directory.
"
" Usage:
"   Use <M-PageUp> and <M-PageDown> to move the current tab anathor position.

function MoveCurrentTab(value)
  if a:value == 0
    return
  endif
  let move = a:value - 1
  let move_to = tabpagenr() + move
  if move_to < 0
    let move_to = 0
  endif
  exe 'tabmove '.move_to
endfunction

map <silent> <M-PageUp> :call MoveCurrentTab(-1)<Esc>
map <silent> <M-PageDown> :call MoveCurrentTab(1)<Esc>
