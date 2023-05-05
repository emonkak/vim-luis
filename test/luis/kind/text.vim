let s:kind = g:luis#kind#text#export

function! s:test_action_open() abort
  enew
  call setline(1, 'hello!')
  normal! $
  try
    silent let _ = luis#do_action(s:kind, 'open', {
    \   'word': ' vim',
    \ })
    call assert_equal(['hello vim!'], getline(1, line('$')))
  finally
    silent bwipeout!
  endtry
endfunction

function! s:test_action_open_x() abort
  enew
  call setline(1, 'hello!')
  normal! $
  try
    silent let _ = luis#do_action(s:kind, 'open!', {
    \   'word': ' vim',
    \ })
    call assert_equal(['hello! vim'], getline(1, line('$')))
  finally
    silent bwipeout!
  endtry
endfunction

function! s:test_kind_definition() abort
  let schema = luis#_scope().SCHEMA_KIND
  let errors = luis#schema#validate(schema, s:kind)
  call assert_equal([], errors)
  call assert_equal('text', s:kind.name)
endfunction
