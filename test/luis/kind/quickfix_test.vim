let s:kind = luis#kind#quickfix#import()

function! s:test_action_open() abort
  cgetexpr ['A:12:foo', 'B:24:bar', 'B:36:bar', 'D:baz']

  let bufnr_A = bufnr('A')
  let bufnr_B = bufnr('B')

  call assert_equal([1, 1, 1, 0], map(getqflist(), 'v:val.valid'))
  call assert_equal([bufnr_A, bufnr_B, bufnr_B, 0], map(getqflist(), 'v:val.bufnr'))

  enew
  let bufnr = bufnr('%')

  try
    let Action = s:kind.action_table.open

    let candidate = {
    \   'word': 'A',
    \   'user_data': {
    \     'quickfix_nr': 1,
    \   },
    \ }
    silent let _ = Action(candidate, {})
    call assert_equal(0, _)
    call assert_equal(bufnr_A, bufnr('%'))

    let candidate = {
    \   'word': 'B',
    \   'user_data': {
    \     'quickfix_nr': 2,
    \   },
    \ }
    silent let _ = Action(candidate, {})
    call assert_equal(0, _)
    call assert_equal(bufnr_B, bufnr('%'))

    silent execute bufnr 'buffer'
    setlocal bufhidden=unload
    setlocal modified

    let candidate = {
    \   'word': 'A',
    \   'user_data': {
    \     'quickfix_nr': 1,
    \   },
    \ }
    silent let _ = Action(candidate, {})
    call assert_match('^E37:', _)
    call assert_equal(bufnr, bufnr('%'))
  finally
    silent execute 'bwipeout!' bufnr_A bufnr_B bufnr 
    call setqflist([])
    call assert_equal([], getqflist())
  endtry
endfunction

function! s:test_action_open_x() abort
  cgetexpr ['A:12:foo', 'B:24:bar', 'B:36:bar', 'D:baz']

  let bufnr_A = bufnr('A')
  let bufnr_B = bufnr('B')

  call assert_equal([1, 1, 1, 0], map(getqflist(), 'v:val.valid'))
  call assert_equal([bufnr_A, bufnr_B, bufnr_B, 0], map(getqflist(), 'v:val.bufnr'))

  enew
  setlocal bufhidden=unload
  setlocal modified
  let bufnr = bufnr('%')

  try
    let Action = s:kind.action_table['open!']

    let candidate = {
    \   'word': 'A',
    \   'user_data': {
    \     'quickfix_nr': 1,
    \   },
    \ }
    silent let _ = Action(candidate, {})
    call assert_equal(0, _)
    call assert_equal(bufnr_A, bufnr('%'))

    let candidate = {
    \   'word': 'B',
    \   'user_data': {
    \     'quickfix_nr': 2,
    \   },
    \ }
    silent let _ = Action(candidate, {})
    call assert_equal(0, _)
    call assert_equal(bufnr_B, bufnr('%'))
  finally
    silent execute 'bwipeout!' bufnr_A bufnr_B bufnr 
    call setqflist([])
    call assert_equal([], getqflist())
  endtry
endfunction

function! s:test_kind_definition() abort
  call assert_true(luis#_validate_kind(s:kind))
  call assert_equal('quickfix', s:kind.name)
endfunction
