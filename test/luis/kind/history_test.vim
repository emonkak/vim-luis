let s:ttyin = has('nvim')
\             || (has('patch-8.0.96')
\                 ? has('ttyin')
\                 : has('unix') && libcallnr('', 'isatty', 0))

let s:kind = luis#kind#history#import()

function! s:test_action_delete() abort
  call histdel('cmd')

  call assert_equal(-1, histnr('cmd'))
  call assert_true(histadd('cmd', 'vim'))
  call assert_equal(1, histnr('cmd'))
  call assert_equal('vim', histget('cmd', 1))

  try
    let Action = s:kind.action_table.delete
    let candidate = {
    \   'word': 'vim',
    \   'user_data': { 'history_name': 'cmd', 'history_index': 1 },
    \ }
    let _ = Action(candidate, {})
    call assert_equal(0, _)
    call assert_equal('', histget('cmd', 1))
  finally
    call histdel('cmd')
  endtry
endfunction

function! s:test_action_delete__no_history() abort
  let Action = s:kind.action_table.delete
  let candidate = {
  \   'word': 'vim',
  \   'user_data': {},
  \ }
  let _ = Action(candidate, {})
  call assert_equal('No history chosen', _)
endfunction

function! s:test_action_open__cmd_history() abort
  if !s:ttyin
    return 'TTY is required.'
  endif

  let Action = s:kind.action_table.open
  let candidate = {
  \   'word': 'vim',
  \   'user_data': { 'history_name': 'cmd' },
  \ }
  let _ = Action(candidate, {})
  call assert_equal(0, _)
  call assert_equal(":vim", s:consume_keys())
endfunction

function! s:test_action_open__search_history() abort
  if !s:ttyin
    return 'TTY is required.'
  endif

  let Action = s:kind.action_table.open
  let candidate = {
  \   'word': 'vim',
  \   'user_data': { 'history_name': 'search' },
  \ }
  let _ = Action(candidate, {})
  call assert_equal(0, _)
  call assert_equal('/vim', s:consume_keys())
endfunction

function! s:test_action_open__expr_history() abort
  if !s:ttyin
    return 'TTY is required.'
  endif

  let Action = s:kind.action_table.open
  let candidate = {
  \   'word': 'vim',
  \   'user_data': { 'history_name': 'expr' },
  \ }
  let _ = Action(candidate, {})
  call assert_equal(0, _)
  call assert_equal("i\<C-r>=vim", s:consume_keys())
endfunction

function! s:test_action_open__input_history() abort
  enew
  call setline(1, 'hello!')
  normal! $
  try
    let Action = s:kind.action_table.open
    let candidate = {
    \   'word': ' vim',
    \   'user_data': { 'history_name': 'input' },
    \ }
    silent let _ = Action(candidate, {})
    call assert_equal(0, _)
    call assert_equal(['hello vim!'], getline(1, line('$')))
  finally
    silent bwipeout!
  endtry
endfunction

function! s:test_action_open__no_history() abort
  let Action = s:kind.action_table.open
  let candidate = {
  \   'word': 'vim',
  \   'user_data': {},
  \ }
  let _ = Action(candidate, {})
  call assert_equal('No history chosen', _)
endfunction

function! s:test_action_open_x__cmd_history() abort
  if !s:ttyin
    return 'TTY is required.'
  endif

  let Action = s:kind.action_table['open!']
  let candidate = {
  \   'word': 'vim',
  \   'user_data': { 'history_name': 'cmd' },
  \ }
  let _ = Action(candidate, {})
  call assert_equal(0, _)
  call assert_equal(':vim', s:consume_keys())
endfunction

function! s:test_action_open_x__search_history() abort
  if !s:ttyin
    return 'TTY is required.'
  endif

  let Action = s:kind.action_table['open!']
  let candidate = {
  \   'word': 'vim',
  \   'user_data': { 'history_name': 'search' },
  \ }
  let _ = Action(candidate, {})
  call assert_equal(0, _)
  call assert_equal('?vim', s:consume_keys())
endfunction

function! s:test_action_open_x__expr_history() abort
  if !s:ttyin
    return 'TTY is required.'
  endif

  let Action = s:kind.action_table['open!']
  let candidate = {
  \   'word': 'vim',
  \   'user_data': { 'history_name': 'expr' },
  \ }
  let _ = Action(candidate, {})
  call assert_equal(0, _)
  call assert_equal("a\<C-r>=vim", s:consume_keys())
endfunction

function! s:test_action_open_x__input_history() abort
  enew
  call setline(1, 'hello!')
  normal! $
  try
    let Action = s:kind.action_table['open!']
    let candidate = {
    \   'word': ' vim',
    \   'user_data': { 'history_name': 'input' },
    \ }
    silent let _ = Action(candidate, {})
    call assert_equal(0, _)
    call assert_equal(['hello! vim'], getline(1, line('$')))
  finally
    silent bwipeout!
  endtry
endfunction

function! s:test_action_open_x__no_history() abort
  let Action = s:kind.action_table['open!']
  let candidate = {
  \   'word': 'vim',
  \   'user_data': {},
  \ }
  let _ = Action(candidate, {})
  call assert_equal('No history chosen', _)
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
