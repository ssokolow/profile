" creamStatus.vim
" A partial extraction of the Cream statusline with a few modifications:
" - The filestate pretty-printer uses a + rather than a * for "modified" and,
"   going above and beyond the call of Cream, will also display a "P" for
"   the preview window.
" - The filetype display will add -bom if the bomb flag is set.
" - The buffer size pretty-printer will use larger units than bytes.
"   (Requires vim 7.2+ for Floating Point... but could be done with integers)
" - Functions have been renamed to signify their non-reliance on cream-lib and
"   their partial non-equivalence to their Cream ancestors.
" - The row, column display now shows total rows and columns too.
" - A "Bufs:" section was added to show a count of `:ls`-able buffers
" - The vertical separators were switched from pipe characters to box-drawing
"   characters as part of my ongoing effort to make Vim look nicer and
"   a scriptencoding declaration was added as a result.
"
" All functions based on equivalent functions from Cream 0.34.
" Both Cream 0.34 and this are licensed under the GNU GPL v2.
" Unless otherwise stated, functions were taken from cream-statusline.vim

" Avoid reinclusion
if exists('g:loaded_creamStatus') && !exists('g:force_reload_creamStatus')
  finish
endif

scriptencoding utf8

let g:loaded_creamStatus = 1

let g:virtualenv_stl_format = '[%n]'

function s:InitStatusLine()
    set statusline=%f
    set statusline+=\ %{Filestate_prettyprint()}
    set statusline+=\│%{CompType()}
    set statusline+=%{&ff}:%{(len(&fenc)?&fenc:&enc).(&bomb?'-bom':'')}
    set statusline+=:%{len(&ft)?&ft:'none'}\│%{Bufsize_prettyprint()}
    if exists('*virtualenv#statusline') == 1
        set statusline+=\ %{virtualenv#statusline()}
    endif
    set statusline+=%=
    set statusline+=\│Bufs:\ %{GetNumBuffers()}
    set statusline+=\│Indent:\ %{GetIndentLevel()}\│%{Mode_prettyprint()}\│
    set statusline+=\ %5.5l/%L,%3.3v/%-3.3{virtcol('$')}\ %P
    set laststatus=2
endfunction

call s:InitStatusLine()
augroup creamStatus
    au!
    autocmd! BufRead * call s:InitStatusLine()
augroup END

function! Filestate_prettyprint()
    " This originated as Cream_statusline_filestate()

    " test read-only state once
    if !exists('b:is_readonly')
        let fpath = expand('%:p')
        let b:is_readonly = fpath ? filewritable(fpath) : 1
    endif

    " preview window
    if &previewwindow
        return 'P'
    " help file
    elseif &buftype ==# 'help'
        return 'H'
    " writable
    elseif b:is_readonly == 0 || &buftype ==# 'nowrite'
        return '-'
    " modified
    elseif &modified != 0
        return '+'
    " unmodified
    else
        return ' '
    endif
endfunction

function! Fenc_prettyprint()
    let fen = len(&fileencoding) ? &fileencoding : &encoding
    let fen = fen . &bomb ? '-bom' : ''
    return fen
endfunction

function! Bufsize_prettyprint()
    " Adapted from Cream_statusline_bufsize().
    let bufsize = line2byte(line('$') + 1) - 1

    " prevent negative numbers (non-existant buffers)
    let bufsize = bufsize < 0 ? 0 : bufsize

    " convert units for human-readability
    let unit_list = ['b', 'kb', 'mb', 'gb', 'tb', 'pb', 'eb']
    let unit_idx = 0
    while bufsize >= 1024
        let bufsize = bufsize / 1024.0
        let unit_idx += 1
    endwhile
    let unit = unit_list[unit_idx]

    " Pretty-print it
    if type(bufsize) == type(0.0) && has('float')
            return printf('%.1f%s', bufsize, unit)
    else
            return bufsize . unit
    endif
endfunction

function! Mode_prettyprint()
    " Adapted from Cream_statusline_modeOK()
    " Called what it is because capitals are prettier here and some ignored
    " chars are too ugly to put in a status line verbatim.
    let mymode = mode()
    if     mymode ==? 'i'  | return 'I'
    elseif mymode ==? 'v'  | return 'V'
    elseif mymode ==? 's'  | return 'S'
    elseif mymode ==? 'R'  | return 'R'
    elseif mymode ==? '' | return 'C'
    elseif mymode ==? 'n'  | return 'N'
    else                   | return ' '
    endif
endfunction

function CompType()
    if exists('b:comptype')
        return b:comptype . ':'
    else
        return ''
    endif
endfunction

function GetIndentLevel()
    " http://vim.wikia.com/wiki/Put_the_indentation_level_on_the_status_line
    " (Padded to prevent the statusline from jittering when scrolling)
    return printf('%2d', indent('.') / &shiftwidth)
endfunction

function! GetNumBuffers()
    " Source: https://superuser.com/a/1221514/48014
    return len(getbufinfo({'buflisted': 1}))
endfunction
