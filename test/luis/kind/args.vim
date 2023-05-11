let s:kind = g:luis#kind#args#export

function! s:test_action_argdelete() abort
  argadd foo bar baz
  call assert_equal(3, argc())
  call assert_equal(['foo', 'bar', 'baz'], argv())

  try
    let _ = luis#internal#do_action(s:kind, 'argdelete', {
    \  'word': 'bar',
    \ })
    call assert_equal(0, _)
    call assert_equal(2, argc())
    call assert_equal(['foo', 'baz'], argv())
  finally
    argdelete *
    silent %bwipeout
    call assert_equal(0, argc())
    call assert_equal([], argv())
  endtry
endfunction

function! s:test_action_argdelete__invalid_arg() abort
  try
    let _ = luis#internal#do_action(s:kind, 'argdelete', {
    \  'word': '_',
    \ })
    call assert_match('Vim(argdelete):E480:', _)
  endtry
endfunction

function! s:test_kind_definition() abort
  call assert_equal([], luis#internal#validate_kind(s:kind))
  call assert_equal('args', s:kind.name)
endfunction
