function! s:action_open(candidate, context) abort
  edit `=a:candidate.word`
  return 0
endfunction

let s:kind = {
\   'name': 'test',
\   'action_table': {
\     'open': function('s:action_open'),
\   },
\   'key_table': {},
\   'prototype': luis#kind#common#import(),
\ }

function! s:test_action_Bottom() abort
  " Before Action:
  " +---------+---------+
  " |         |         |
  " |   [1]   |    2    |
  " |         |         |
  " +---------+---------+
  " |                   |
  " |         3         |
  " |                   |
  " +---------+---------+
  " After Action:
  " +---------+---------+
  " |         |         |
  " |    1    |    2    |
  " |         |         |
  " +---------+---------+
  " |         3         |
  " +---------+---------+
  " |        [4]        |
  " +---------+---------+
  call s:do_test_split(4, [3, 0, 0, 0], 1, 'Bottom', 'aboveleft', 'aboveleft')

  " +-------------------+
  " |         1         |
  " +-------------------+
  " |         2         |
  " +-------------------+
  " |         :         |
  " +-------------------+
  " |         n         |
  " +-------------------+
  call s:do_test_split_without_enough_room('Bottom', '')
endfunction

function! s:test_action_Left() abort
  " Before Action:
  " +-------------------+
  " |                   |
  " |         1         |
  " |                   |
  " +---------+---------+
  " |         |         |
  " |    2    |   [3]   |
  " |         |         |
  " +---------+---------+
  " After Action:
  " +---------+---------+
  " |         |         |
  " |         |    2    |
  " |         |         |
  " |   [1]   +----+----+
  " |         |    |    |
  " |         | 3  | 4  |
  " |         |    |    |
  " +---------+----+----+
  call s:do_test_split(1, [0, 2, 0, 0], 1, 'Left', 'belowright', 'belowright')

  " +----+----+----+----+
  " |    |    |    |    |
  " |    |    |    |    |
  " |    |    |    |    |
  " | 1  | 2  | .. | n  |
  " |    |    |    |    |
  " |    |    |    |    |
  " |    |    |    |    |
  " +----+----+----+----+
  call s:do_test_split_without_enough_room('Left', 'vertical')
endfunction

function! s:test_action_Right() abort
  " Before Action:
  " +-------------------+
  " |                   |
  " |         1         |
  " |                   |
  " +---------+---------+
  " |         |         |
  " |   [2]   |    3    |
  " |         |         |
  " +---------+---------+
  " After Action:
  " +---------+---------+
  " |         |         |
  " |    1    |         |
  " |         |         |
  " +----+----+   [4]   |
  " |    |    |         |
  " | 2  | 3  |         |
  " |    |    |         |
  " +----+----+---------+
  call s:do_test_split(4, [0, 0, 0, 1], 1, 'Right', 'belowright', 'aboveleft')

  " +----+----+----+----+
  " |    |    |    |    |
  " |    |    |    |    |
  " |    |    |    |    |
  " | 1  | 2  | .. | n  |
  " |    |    |    |    |
  " |    |    |    |    |
  " |    |    |    |    |
  " +----+----+----+----+
  call s:do_test_split_without_enough_room('Right', 'vertical')
endfunction

function! s:test_action_Top() abort
  " Before Action:
  " +-------------------+
  " |                   |
  " |         1         |
  " |                   |
  " +---------+---------+
  " |         |         |
  " |    2    |   [3]   |
  " |         |         |
  " +---------+---------+
  " After Action:
  " +-------------------+
  " |        [1]        |
  " +-------------------+
  " |         2         |
  " +---------+---------+
  " |         |         |
  " |    1    |    2    |
  " |         |         |
  " +---------+---------+
  call s:do_test_split(1, [0, 0, 2, 0], 1, 'Top', 'belowright', 'belowright')

  " +-------------------+
  " |         1         |
  " +-------------------+
  " |         2         |
  " +-------------------+
  " |         :         |
  " +-------------------+
  " |         n         |
  " +-------------------+
  call s:do_test_split_without_enough_room('Top', '')
endfunction

function! s:test_action_Yank() abort
  let reg_value = getreg('"', 1)
  let reg_type = getregtype('"')
  let @" = 'foo'
  try
    let Action = s:kind.prototype.action_table.Yank
    let _ = Action({ 'word': 'bar' }, {})
    call assert_equal(0, _)
    call assert_equal("bar\n", getreg('"', 1))
    call assert_equal('V', getregtype('"'))
  finally
    call setreg('"', reg_value, reg_type)
  endtry
endfunction

function! s:test_action_above() abort
  " Before Action:
  " +-------------------+
  " |                   |
  " |         1         |
  " |                   |
  " +---------+---------+
  " |         |         |
  " |    2    |   [3]   |
  " |         |         |
  " +---------+---------+
  " After Action:
  " +-------------------+
  " |                   |
  " |         1         |
  " |                   |
  " +---------+---------+
  " |         |   [3]   |
  " |    2    +---------+
  " |         |    4    |
  " +---------+---------+
  call s:do_test_split(3, [1, 0, 4, 2], 1, 'above', 'belowright', 'belowright')

  " +-------------------+
  " |         1         |
  " +-------------------+
  " |         2         |
  " +-------------------+
  " |         :         |
  " +-------------------+
  " |         n         |
  " +-------------------+
  call s:do_test_split_without_enough_room('above', '')
endfunction

function! s:test_action_below() abort
  " Before Action:
  " +---------+---------+
  " |         |         |
  " |   [1]   |    2    |
  " |         |         |
  " +---------+---------+
  " |                   |
  " |         3         |
  " |                   |
  " +---------+---------+
  " After Action:
  " +---------+---------+
  " |    1    |         |
  " +---------+    3    |
  " |   [2]   |         |
  " +---------+---------+
  " |                   |
  " |         4         |
  " |                   |
  " +---------+---------+
  call s:do_test_split(2, [1, 3, 4, 0], 1, 'below', 'aboveleft', 'aboveleft')

  " +-------------------+
  " |         1         |
  " +-------------------+
  " |         2         |
  " +-------------------+
  " |         :         |
  " +-------------------+
  " |         n         |
  " +-------------------+
  call s:do_test_split_without_enough_room('below', '')
endfunction

function! s:test_action_cancel() abort
  let Action = s:kind.prototype.action_table.cancel
  let _ = Action({}, {})
  call assert_equal(0, _)
endfunction

function! s:test_action_ex() abort
  let Action = s:kind.prototype.action_table.ex

  let _ = Action({ 'word': 'vim' }, {})
  call assert_equal(0, _)
  call assert_equal(": vim\<C-b>", s:consume_keys())

  let _ = Action({ 'word': 'v i' }, {})
  call assert_equal(0, _)
  call assert_equal(": v\\ i\<C-b>", s:consume_keys())
endfunction

function! s:test_action_left() abort
  " Before Action:
  " +-------------------+
  " |                   |
  " |         1         |
  " |                   |
  " +---------+---------+
  " |         |         |
  " |    2    |   [3]   |
  " |         |         |
  " +---------+---------+
  " After Action:
  " +-------------------+
  " |                   |
  " |         1         |
  " |                   |
  " +---------+----+----+
  " |         |    |    |
  " |    2    |[3] | 4  |
  " |         |    |    |
  " +---------+----+----+
  call s:do_test_split(3, [1, 4, 0, 2], 1, 'left', 'belowright', 'belowright')

  " +----+----+----+----+
  " |    |    |    |    |
  " |    |    |    |    |
  " |    |    |    |    |
  " | 1  | 2  | .. | n  |
  " |    |    |    |    |
  " |    |    |    |    |
  " |    |    |    |    |
  " +----+----+----+----+
  call s:do_test_split_without_enough_room('left', 'vertical')
endfunction

function! s:test_action_open() abort
  for Action in [
  \   s:kind.action_table['open'],
  \   s:kind.prototype.action_table['open!'],
  \   s:kind.prototype.action_table['default'],
  \ ]
    let candidate = { 'word': tempname() }
    let context = { 'kind': s:kind }
    silent let _ = Action(candidate, context)
    call assert_equal(0, _)
    call assert_equal(candidate.word, bufname('%'))
    silent execute 'bwipeout' candidate.word
  endfor
endfunction

function! s:test_action_open__not_defined() abort
  let Action = s:kind.prototype.action_table.open
  let _ = Action({}, {})
  call assert_notequal(0, _)
endfunction

function! s:test_action_put() abort
  enew
  try
    let Action = s:kind.prototype.action_table.put
    let _ = Action({ 'word': 'VIM' }, {})
    call assert_equal(0, _)
    call assert_equal(['', 'VIM'], getline(1, line('$')))
  finally
    silent bwipeout!
  endtry
endfunction

function! s:test_action_put_x() abort
  enew
  try
    let Action = s:kind.prototype.action_table['put!']
    let _ = Action({ 'word': 'VIM' }, {})
    call assert_equal(0, _)
    call assert_equal(['VIM', ''], getline(1, line('$')))
  finally
    silent bwipeout!
  endtry
endfunction

function! s:test_action_reselect() abort
  let [session, session_spies] = SpyDict({
  \   'start': { -> 0 },
  \ })

  let Action = s:kind.prototype.action_table.reselect
  let _ = Action({ 'word': 'XXX' }, { 'session': session })
  call assert_equal(0, _)
  call assert_equal(1, session_spies.start.call_count())
  call assert_equal(session, session_spies.start.last_self())
endfunction

function! s:test_action_right() abort
  " Before Action:
  " +-------------------+
  " |                   |
  " |         1         |
  " |                   |
  " +---------+---------+
  " |         |         |
  " |   [2]   |    3    |
  " |         |         |
  " +---------+---------+
  " After Action:
  " +---------+---------+
  " |                   |
  " |         1         |
  " |                   |
  " |----+--------------+
  " |    |    |         |
  " | 2  |[3] |    4    |
  " |    |    |         |
  " +----+----+---------+
  call s:do_test_split(3, [1, 4, 0, 2], 1, 'right', 'belowright', 'aboveleft')

  " +----+----+----+----+
  " |    |    |    |    |
  " |    |    |    |    |
  " |    |    |    |    |
  " | 1  | 2  | .. | n  |
  " |    |    |    |    |
  " |    |    |    |    |
  " |    |    |    |    |
  " +----+----+----+----+
  call s:do_test_split_without_enough_room('right', 'vertical')
endfunction

function! s:test_action_tab_Left() abort
  " Before Action:
  " +-----+-----+-----+
  " |  1  | [2] |  3  |
  " +-----+-----+-----+
  " After Action:
  " +-----+-----+-----+-----+
  " | [1] |  2  |  3  |  4  |
  " +-----+-----+-----+-----+
  call s:do_test_tab(1, 'tab-Left')
endfunction

function! s:test_action_tab_Right() abort
  " Before Action:
  " +-----+-----+-----+
  " |  1  | [2] |  3  |
  " +-----+-----+-----+
  " After Action:
  " +-----+-----+-----+-----+
  " |  1  |  2  |  3  | [4] |
  " +-----+-----+-----+-----+
  call s:do_test_tab(4, 'tab-Right')
endfunction

function! s:test_action_tab_left() abort
  " Before Action:
  " +-----+-----+-----+
  " |  1  | [2] |  3  |
  " +-----+-----+-----+
  " After Action:
  " +-----+-----+-----+-----+
  " |  1  | [2] |  3  |  4  |
  " +-----+-----+-----+-----+
  call s:do_test_tab(2, 'tab-left')
endfunction

function! s:test_action_tab_right() abort
  " Before Action:
  " +-----+-----+-----+
  " |  1  | [2] |  3  |
  " +-----+-----+-----+
  " After Action:
  " +-----+-----+-----+-----+
  " |  1  |  2  | [3] |  4  |
  " +-----+-----+-----+-----+
  call s:do_test_tab(3, 'tab-right')
endfunction

function! s:test_action_yank() abort
  let reg_value = getreg('"', 1)
  let reg_type = getregtype('"')
  let @" = 'foo'
  try
    let Action = s:kind.prototype.action_table.yank
    let _ = Action({ 'word': 'bar' }, {})
    call assert_equal(0, _)
    call assert_equal('bar', getreg('"', 1))
    call assert_equal('v', getregtype('"'))
  finally
    call setreg('"', reg_value, reg_type)
  endtry
endfunction

function! s:consume_keys() abort
  let keys = ''
  while 1
    let char = getchar(0)
    if char is 0
      break
    endif
    let keys .= nr2char(char)
  endwhile
  return keys
endfunction

function! s:do_test_split(expected_winnr, expected_neighbor_windows, expected_tabpagenr, action_name, hsplit_modifier, vsplit_modifier) abort
  let original_bufnr = bufnr('%')

  execute a:hsplit_modifier 'new'
  execute a:vsplit_modifier 'vnew'

  call assert_notequal(original_bufnr, bufnr('%'))
  call assert_equal(3, winnr('$'))

  try
    let candidate = { 'word': tempname() }
    let Action = s:kind.prototype.action_table[a:action_name]
    let context = { 'kind': s:kind }
    silent let _ = Action(candidate, context)
    call assert_equal(0, _)

    call assert_equal(candidate.word, bufname('%'))
    call assert_equal(a:expected_winnr, winnr())
    call assert_equal(a:expected_neighbor_windows, s:neighbor_windows())
    call assert_equal(4, winnr('$'))

    silent execute 'bwipeout' candidate.word
  finally
    execute bufwinnr(original_bufnr) 'wincmd w'
    only

    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr('$'))
  endtry
endfunction

function! s:do_test_split_without_enough_room(action_name, orientation) abort
  let v:errmsg = ''
  while v:errmsg == ''
    silent! execute a:orientation 'new'
    execute 'wincmd' (a:orientation ==# 'vertical' ? '|' : '_')
  endwhile

  let original_bufnr = bufnr('%')
  let original_last_winnr = winnr('$')

  try
    let Action = s:kind.prototype.action_table[a:action_name]
    let context = { 'kind': s:kind }
    silent let _ = Action({ 'word': 'XXX' }, context)
    call assert_match('Vim(split):E36: Not enough room', _)

    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(original_last_winnr, winnr('$'))
  finally
    execute bufwinnr(original_bufnr) 'wincmd w'
    only

    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, winnr('$'))
  endtry
endfunction

function! s:do_test_tab(expected_tabpagenr, action_name) abort
  let original_bufnr = bufnr('%')
  let original_winid = win_getid()

  0tabnew
  $tabnew
  tabprevious

  call assert_equal(original_bufnr, bufnr('%'))
  call assert_equal(2, tabpagenr())
  call assert_equal(3, tabpagenr('$'))

  try
    let Action = s:kind.prototype.action_table[a:action_name]
    let candidate = { 'word': tempname() }
    let context = { 'kind': s:kind }
    silent let _ = Action(candidate, context)
    call assert_equal(0, _)

    call assert_equal(candidate.word, bufname('%'))
    call assert_equal(a:expected_tabpagenr, tabpagenr())
    call assert_equal(4, tabpagenr('$'))

    silent execute 'bwipeout' candidate.word
  finally
    execute win_id2tabwin(original_winid)[0] 'tabnext'
    tabonly

    call assert_equal(original_bufnr, bufnr('%'))
    call assert_equal(1, tabpagenr('$'))
  endtry
endfunction

function! s:neighbor_windows() abort
  let original_winnr = winnr()
  let neighbor_windows = []

  for direction in ['k', 'l', 'j', 'h']
    execute 'wincmd' direction
    let winnr = winnr()
    call add(neighbor_windows, winnr != original_winnr ? winnr : 0)
    execute original_winnr 'wincmd w'
  endfor

  return neighbor_windows
endfunction
