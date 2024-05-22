let s:kind = luis#kind#jumplist#import()

function! s:test_action_open() abort
  if !exists('*getjumplist')
    return 'getjumplist() function is required.'
  endif

  new
  let window = win_getid()

  call setline(1, range(1, 10))
  clearjumps
  normal! 2gg
  normal! 4gg
  normal! 8gg
  normal! 10gg
  execute 'normal!' "\<C-o>"

  call assert_equal([1, 2, 4, 8, 10], map(get(getjumplist(window), 0, []), 'v:val.lnum'))
  call assert_equal(3, get(getjumplist(window), 1, -1))
  call assert_equal(8, line('.'))

  let Action = s:kind.action_table.open

  try
    let candidate = {
    \   'user_data': {
    \     'jumplist_index': 4,
    \     'jumplist_window': window,
    \   },
    \ }
    silent call Action(candidate, {})
    call assert_equal(4, get(getjumplist(window), 1, -1))
    call assert_equal(10, line('.'))

    let candidate = {
    \   'user_data': {
    \     'jumplist_index': 2,
    \     'jumplist_window': window,
    \   },
    \ }
    silent call Action(candidate, {})
    call assert_equal(2, get(getjumplist(window), 1, -1))
    call assert_equal(4, line('.'))

    let candidate = {
    \   'user_data': {
    \     'jumplist_index': 0,
    \     'jumplist_window': window,
    \   },
    \ }
    silent call Action(candidate, {})
    call assert_equal(0, get(getjumplist(window), 1, -1))
    call assert_equal(1, line('.'))

    let candidate = {
    \   'user_data': {
    \     'jumplist_index': 3,
    \     'jumplist_window': window,
    \   },
    \ }
    silent call Action(candidate, {})
    call assert_equal(3, get(getjumplist(window), 1, -1))
    call assert_equal(8, line('.'))
  finally
    bwipeout!
  endtry
endfunction

function! s:test_action_open__no_jump() abort
  let Action = s:kind.action_table.open
  let candidate = {
  \   'word': 'vim',
  \   'user_data': {},
  \ }
  call s:assert_exception(
  \   'No jump chosen',
  \   { -> Action(candidate, {}) }
  \ )
endfunction

function! s:assert_exception(expected_message, callback)
  try
    silent call a:callback()
    call assert_true(0, 'Function must throw an exception')
  catch
    call assert_exception(a:expected_message)
  endtry
endfunction
