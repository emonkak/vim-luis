let s:kind = g:luis#kind#mark#export

function! s:test_action_delete() abort
  enew!
  mark a
  let bufnr = bufnr('%')

  call assert_notequal('', execute('marks a', 'silent!'))

  try
    let _ = luis#do_action(s:kind, 'delete', {
    \   'word': 'bar',
    \   'user_data': {
    \     'mark_name': 'a',
    \   },
    \ })
    call assert_equal(0, _)
    call assert_equal('', execute('marks a', 'silent!'))
  finally
    execute bufnr 'bwipeout!'
  endtry
endfunction

function! s:test_action_delete__no_mark() abort
  let _ = luis#do_action(s:kind, 'delete', {
  \   'word': '',
  \   'user_data': {},
  \ })
  call assert_equal('No mark chosen', _)
endfunction

function! s:test_action_open() abort
  enew!
  call setline(1, range(1, 10))
  5mark a
  let bufnr = bufnr('%')

  call assert_equal(1, line('.'))

  try
    let _ = luis#do_action(s:kind, 'open', {
    \   'word': 'bar',
    \   'user_data': {
    \     'mark_name': 'a',
    \   },
    \ })
    call assert_equal(0, _)
    call assert_equal(5, line('.'))
  finally
    execute bufnr 'bwipeout!'
  endtry
endfunction

function! s:test_action_open__no_mark() abort
  let _ = luis#do_action(s:kind, 'open', {
  \   'word': '',
  \   'user_data': {},
  \ })
  call assert_equal('No mark chosen', _)
endfunction

function! s:test_kind_definition() abort
  let schema = luis#_scope().SCHEMA_KIND
  let errors = luis#schema#validate(schema, s:kind)
  call assert_equal([], errors)
  call assert_equal('mark', s:kind.name)
endfunction
