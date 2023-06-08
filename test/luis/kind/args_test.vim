let s:kind = luis#kind#args#import()

function! s:test_action_argdelete() abort
  argadd foo bar baz
  call assert_equal(3, argc())
  call assert_equal(['foo', 'bar', 'baz'], argv())

  try
    let Action = s:kind.action_table.argdelete
    let _ = Action({ 'word': 'bar', 'user_data': { 'args_index': 1 } }, {})
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

function! s:test_action_argdelete__no_argument_chosen() abort
  try
    let Action = s:kind.action_table.argdelete
    let _ = Action({ 'word': 'bar', 'user_data': {} }, {})
    call assert_match('No argument chosen', _)
  endtry
endfunction

function! s:test_action_open() abort
  argadd foo bar baz
  call assert_equal(3, argc())
  call assert_equal(['foo', 'bar', 'baz'], argv())

  let Action = s:kind.action_table.open

  try
    let candidate = {
    \  'word': 'foo',
    \  'user_data': { 'args_index': 0 },
    \ }
    silent call assert_equal(0, Action(candidate, {}))
    call assert_equal('foo', bufname('%'))

    let candidate = {
    \  'word': 'bar',
    \  'user_data': { 'args_index': 1 },
    \ }
    silent call assert_equal(0, Action(candidate, {}))
    call assert_equal('bar', bufname('%'))

    let candidate = {
    \  'word': 'baz',
    \  'user_data': { 'args_index': 2 },
    \ }
    silent call assert_equal(0, Action(candidate, {}))
    call assert_equal('baz', bufname('%'))
  finally
    argdelete *
    silent %bwipeout
  endtry
endfunction

function! s:test_action_open__invalid_index() abort
  argadd foo bar baz
  call assert_equal(3, argc())
  call assert_equal(['foo', 'bar', 'baz'], argv())


  let Action = s:kind.action_table.open

  try
    let candidate = {
    \  'word': 'foo',
    \  'user_data': { 'args_index': 9 },
    \ }
    silent call assert_match('^E16:', Action(candidate, {}))
  finally
    argdelete *
    silent %bwipeout
  endtry
endfunction

function! s:test_kind_definition() abort
  call assert_true(luis#validate_kind(s:kind))
  call assert_equal('args', s:kind.name)
endfunction
