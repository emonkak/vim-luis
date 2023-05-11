let s:kind = g:luis#kind#history#export

function! s:test_action_delete() abort
  return

  call s:clear_hisotries('cmd')

  call assert_equal(-1, histnr('cmd'))
  call assert_true(histadd('cmd', 'vim'))
  call assert_equal(1, histnr('cmd'))
  call assert_equal('vim', histget('cmd', 1))

  try
    let candidate = {
    \   'word': 'vim',
    \   'user_data': { 'history_name': 'cmd', 'history_index': 1 },
    \ }
    let _ = luis#internal#do_action(s:kind, 'delete', candidate)

    call assert_equal(0, _)
    call assert_equal('', histget('cmd', 1))
  finally
    call s:clear_hisotries('cmd')
  endtry
endfunction

function! s:test_action_delete__no_history() abort
  let candidate = {
  \   'word': 'vim',
  \   'user_data': {},
  \ }
  let _ = luis#internal#do_action(s:kind, 'delete', candidate)
  call assert_equal('No history chosen', _)
endfunction

function! s:test_action_open__cmd_history() abort
  let candidate = {
  \   'word': 'vim',
  \   'user_data': { 'history_name': 'cmd' },
  \ }
  let _ = luis#internal#do_action(s:kind, 'open', candidate)
  call assert_equal(0, _)
  call assert_equal(':vim', s:consume_keys())
endfunction

function! s:test_action_open__search_history() abort
  let candidate = {
  \   'word': 'vim',
  \   'user_data': { 'history_name': 'search' },
  \ }
  let _ = luis#internal#do_action(s:kind, 'open', candidate)
  call assert_equal(0, _)
  call assert_equal('/vim', s:consume_keys())
endfunction

function! s:test_action_open__expr_history() abort
  let candidate = {
  \   'word': 'vim',
  \   'user_data': { 'history_name': 'expr' },
  \ }
  let _ = luis#internal#do_action(s:kind, 'open', candidate)
  call assert_equal(0, _)
  call assert_equal("i\<C-r>=vim", s:consume_keys())
endfunction

function! s:test_action_open__input_history() abort
  enew
  call setline(1, 'hello!')
  normal! $
  try
    let candidate = {
    \   'word': ' vim',
    \   'user_data': { 'history_name': 'input' },
    \ }
    silent let _ = luis#internal#do_action(s:kind, 'open', candidate)
    call assert_equal(0, _)
    call assert_equal(['hello vim!'], getline(1, line('$')))
  finally
    silent bwipeout!
  endtry
endfunction

function! s:test_action_open__no_history() abort
  let candidate = {
  \   'word': 'vim',
  \   'user_data': {},
  \ }
  let _ = luis#internal#do_action(s:kind, 'open', candidate)
  call assert_equal('No history chosen', _)
endfunction

function! s:test_action_open_x__cmd_history() abort
  let candidate = {
  \   'word': 'vim',
  \   'user_data': { 'history_name': 'cmd' },
  \ }
  let _ = luis#internal#do_action(s:kind, 'open!', candidate)
  call assert_equal(0, _)
  call assert_equal(':vim', s:consume_keys())
endfunction

function! s:test_action_open_x__search_history() abort
  let candidate = {
  \   'word': 'vim',
  \   'user_data': { 'history_name': 'search' },
  \ }
  let _ = luis#internal#do_action(s:kind, 'open!', candidate)
  call assert_equal(0, _)
  call assert_equal('?vim', s:consume_keys())
endfunction

function! s:test_action_open_x__expr_history() abort
  let candidate = {
  \   'word': 'vim',
  \   'user_data': { 'history_name': 'expr' },
  \ }
  let _ = luis#internal#do_action(s:kind, 'open!', candidate)
  call assert_equal(0, _)
  call assert_equal("a\<C-r>=vim", s:consume_keys())
endfunction

function! s:test_action_open_x__input_history() abort
  enew
  call setline(1, 'hello!')
  normal! $
  try
    let candidate = {
    \   'word': ' vim',
    \   'user_data': { 'history_name': 'input' },
    \ }
    silent let _ = luis#internal#do_action(s:kind, 'open!', candidate)
    call assert_equal(0, _)
    call assert_equal(['hello! vim'], getline(1, line('$')))
  finally
    silent bwipeout!
  endtry
endfunction

function! s:test_action_open_x__no_history() abort
  let candidate = {
  \   'word': 'vim',
  \   'user_data': {},
  \ }
  let _ = luis#internal#do_action(s:kind, 'open!', candidate)
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

function! s:clear_hisotries(history_name) abort
  let l = histnr(a:history_name)
  if l > 1
    for i in range(1, l)
      call histdel(a:history_name, i)
    endfor
  endif
endfunction
