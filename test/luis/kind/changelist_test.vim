let s:kind = luis#kind#changelist#import()

function! s:test_action_open() abort
  if !exists('*getchangelist')
    return 'getchangelist() function is required.'
  endif

  new
  let bufnr = bufnr('%')

  keepjumps call setline(1, range(1, 10))
  call feedkeys("1ggi\<Space>\<BS>", 'ntx')
  call feedkeys("2ggi\<Space>\<BS>", 'ntx')
  call feedkeys("4ggi\<Space>\<BS>", 'ntx')
  call feedkeys("8ggi\<Space>\<BS>", 'ntx')
  call feedkeys("10ggi\<Space>\<BS>", 'ntx')
  normal! 2g;

  call assert_equal(
  \   [[1, 0], [2, 0], [4, 0], [8, 0], [10, 0]],
  \   map(get(getchangelist(bufnr), 0, []), '[v:val.lnum, v:val.col]')
  \ )
  call assert_equal(3, get(getchangelist(bufnr), 1, -1))
  call assert_equal(8, line('.'))

  let Action = s:kind.action_table.open

  try
    let candidate = {
    \   'user_data': {
    \     'changelist_index': 4,
    \     'changelist_bufnr': bufnr,
    \   },
    \ }
    silent call Action(candidate, {})
    call assert_equal(4, get(getchangelist(bufnr), 1, -1))
    call assert_equal(10, line('.'))

    let candidate = {
    \   'user_data': {
    \     'changelist_index': 2,
    \     'changelist_bufnr': bufnr,
    \   },
    \ }
    silent call Action(candidate, {})
    call assert_equal(2, get(getchangelist(bufnr), 1, -1))
    call assert_equal(4, line('.'))

    let candidate = {
    \   'user_data': {
    \     'changelist_index': 0,
    \     'changelist_bufnr': bufnr,
    \   },
    \ }
    silent call Action(candidate, {})
    call assert_equal(0, get(getchangelist(bufnr), 1, -1))
    call assert_equal(1, line('.'))

    let candidate = {
    \   'user_data': {
    \     'changelist_index': 3,
    \     'changelist_bufnr': bufnr,
    \   },
    \ }
    silent call Action(candidate, {})
    call assert_equal(3, get(getchangelist(bufnr), 1, -1))
    call assert_equal(8, line('.'))
  finally
    bwipeout!
  endtry
endfunction

function! s:test_action_open__no_change() abort
  let Action = s:kind.action_table.open
  let candidate = {
  \   'word': 'vim',
  \   'user_data': {},
  \ }
  call s:assert_exception(
  \   'No change chosen',
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
