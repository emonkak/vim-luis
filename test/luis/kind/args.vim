let s:kind = g:luis#kind#args#export

function! s:test_action_argdelete() abort
  argadd foo bar baz
  call assert_equal(3, argc())
  call assert_equal(['foo', 'bar', 'baz'], argv())

  try
    let _ = luis#do_action(s:kind, 'argdelete', {
    \  'word': 'bar',
    \ })
    call assert_equal(0, _)
    call assert_equal(2, argc())
    call assert_equal(['foo', 'baz'], argv())
  finally
    argdelete *
    silent bwipeout foo bar baz
  endtry
endfunction

function! s:test_action_argdelete_invalid_arg() abort
  try
    let _ = luis#do_action(s:kind, 'argdelete', {
    \  'word': '_',
    \ })
    call assert_match('Vim(argdelete):E480:', _)
  endtry
endfunction

function! s:test_kind_definition() abort
  call assert_equal('args', s:kind.name)
  call assert_true(type(s:kind.action_table), v:t_dict)
  call assert_true(type(s:kind.key_table), v:t_dict)
  call assert_equal(s:kind.prototype, g:luis#kind#buffer#export)
endfunction
