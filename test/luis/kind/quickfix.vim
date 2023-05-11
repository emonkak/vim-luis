let s:kind = g:luis#kind#quickfix#export

function s:test_action_open() abort
  cgetexpr ['A:12:foo', 'B:24:bar', 'C:baz']
  call assert_equal([1, 1, 0], map(getqflist(), 'v:val.valid'))
  call assert_equal([bufnr('A'), bufnr('B'), 0], map(getqflist(), 'v:val.bufnr'))

  enew!
  let bufnr = bufnr('%')

  try
    silent let _ = luis#internal#do_action(s:kind, 'open', {
    \   'word': 'xxx',
    \   'user_data': {
    \     'quickfix_nr': 1,
    \   },
    \ })
    call assert_equal(0, _)
    call assert_equal(bufnr('A'), bufnr('%'))

    silent let _ = luis#internal#do_action(s:kind, 'open', {
    \   'word': 'xxx',
    \   'user_data': {
    \     'quickfix_nr': 2,
    \   },
    \ })
    call assert_equal(0, _)
    call assert_equal(bufnr('B'), bufnr('%'))

    silent execute bufnr 'buffer'
    setlocal bufhidden=unload
    setlocal modified

    silent let _ = luis#internal#do_action(s:kind, 'open', {
    \   'word': 'VIM',
    \   'user_data': {
    \     'quickfix_nr': 1,
    \   },
    \ })
    call assert_match('Vim(cc):E37:', _)
    call assert_equal(bufnr, bufnr('%'))
  finally
    cgetexpr []
    silent bwipeout A
    silent bwipeout B
    silent execute bufnr 'bwipeout!'
  endtry
endfunction

function s:test_action_open_x() abort
  cgetexpr ['A:2:foo', 'B:4:bar', 'C:baz']
  call assert_equal([1, 1, 0], map(getqflist(), 'v:val.valid'))
  call assert_equal([bufnr('A'), bufnr('B'), 0], map(getqflist(), 'v:val.bufnr'))

  enew!
  setlocal bufhidden=unload
  setlocal modified
  let bufnr = bufnr('%')

  try
    silent let _ = luis#internal#do_action(s:kind, 'open!', {
    \   'word': 'xxx',
    \   'user_data': {
    \     'quickfix_nr': 1,
    \   },
    \ })
    call assert_equal(0, _)
    call assert_equal(bufnr('A'), bufnr('%'))

    silent let _ = luis#internal#do_action(s:kind, 'open!', {
    \   'word': 'xxx',
    \   'user_data': {
    \     'quickfix_nr': 2,
    \   },
    \ })
    call assert_equal(0, _)
    call assert_equal(bufnr('B'), bufnr('%'))
  finally
    cgetexpr []
    silent bwipeout A
    silent bwipeout B
    silent execute bufnr 'bwipeout!'
  endtry
endfunction

function! s:test_kind_definition() abort
  call assert_equal([], luis#internal#validate_kind(s:kind))
  call assert_equal('quickfix', s:kind.name)
endfunction
