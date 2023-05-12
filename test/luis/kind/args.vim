let s:kind = luis#kind#args#import()

function! s:test_action_argdelete() abort
  argadd foo bar baz
  call assert_equal(3, argc())
  call assert_equal(['foo', 'bar', 'baz'], argv())

  try
    let Action = s:kind.action_table.argdelete
    let _ = Action({ 'word': 'bar' }, {})
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
    let Action = s:kind.action_table.argdelete
    let _ = Action({ 'word': 'XXX' }, {})
    call assert_match('Vim(argdelete):E480:', _)
  endtry
endfunction

function! s:test_kind_definition() abort
  call assert_equal([], luis#_validate_kind(s:kind))
  call assert_equal('args', s:kind.name)
endfunction
