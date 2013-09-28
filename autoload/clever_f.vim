" モードをキーにする辞書で定義
function! clever_f#reset()
    let s:previous_map = {}
    let s:previous_char = {}
    let s:previous_pos = {}
    let s:first_move = {}

    return ""
endfunction

function! clever_f#find_with(map)
    if a:map !~# '^[fFtT]$'
        echoerr 'invalid mapping: ' . a:map
        return
    endif

    let current_pos = getpos('.')[1 : 2]
    let back = 0

    let mode = mode(1)
    if current_pos != get(s:previous_pos, mode, [0, 0])
        let s:previous_char[mode] = getchar()
        let s:previous_map[mode] = a:map
        let s:first_move[mode] = 1
    else
        let back = a:map =~# '\u'
    endif
    return clever_f#repeat(back)
endfunction

function! clever_f#repeat(...)
    let back = a:0 && a:1
    let mode = mode(1)
    let pmap = get(s:previous_map, mode, "")
    let pchar = get(s:previous_char, mode, 0)
    if pmap ==# ''
        return ''
    endif
    if back
        let pmap = s:swapcase(pmap)
    endif

    if mode ==? 'v' || mode ==# "\<C-v>"
        let cmd = s:move_cmd_for_visualmode(pmap, pchar)
    else
        let inclusive = mode ==# 'no' && pmap =~# '\l'
        let cmd = printf("%s:\<C-u>call clever_f#find(%s, %s)\<CR>",
        \                inclusive ? 'v' : '',
        \                string(pmap), pchar)
    endif
    return cmd
endfunction

function! clever_f#find(map, char)
    let next_pos = s:next_pos(a:map, a:char, v:count1)
    if next_pos != [0, 0]
        let mode = mode(1)
        let s:previous_pos[mode] = next_pos
        call cursor(next_pos[0], next_pos[1])
    endif
endfunction

function! s:move_cmd_for_visualmode(map, char)
    let next_pos = s:next_pos(a:map, a:char, v:count1)
    if next_pos == [0, 0]
        return ''
    endif

    call setpos("''", [0] + next_pos + [0])
    let cmd = "``"
    let mode = mode(1)
    let s:previous_pos[mode] = next_pos
    return cmd
endfunction

function! s:search(pat, flag)
    if g:clever_f_across_no_line
        return search(a:pat, a:flag, line('.'))
    else
        return search(a:pat, a:flag)
    endif
endfunction

function! s:next_pos(map, char, count)
    let char = type(a:char) == type(0) ? nr2char(a:char) : a:char
    if a:map ==# 't'
        let target = '\_.\ze' . char
    elseif a:map ==# 'T'
        let target = char . '\@<=\_.'
    else  " a:map ==? 'f'
        let target = char
    endif
    let pat = (g:clever_f_ignore_case ? '\c' : '\C') . '\V' . target
    let search_flag = a:map =~# '\l' ? 'W' : 'bW'

    let cnt = a:count
    let mode = mode(1)
    if get(s:first_move, mode, 0)
        let s:first_move[mode] = 0
        if a:map ==? 't'
            if !s:search(pat, search_flag . 'c')
                return [0, 0]
            endif
            let cnt -= 1
        endif
    endif

    while 0 < cnt
        if !s:search(pat, search_flag)
            return [0, 0]
        endif
        let cnt -= 1
    endwhile
    return getpos('.')[1 : 2]
endfunction

function! s:swapcase(char)
    return a:char =~# '\u' ? tolower(a:char) : toupper(a:char)
endfunction

call clever_f#reset()
