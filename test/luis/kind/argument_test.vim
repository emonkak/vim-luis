let s:kind = luis#kind#argument#import()

function! s:test_action_argdelete() abort
  argadd foo bar baz
  call assert_equal(3, argc())
  call assert_equal(['foo', 'bar', 'baz'], argv())

  try
    let Action = s:kind.action_table.argdelete
    silent call Action({ 'word': 'bar', 'user_data': { 'argument_index': 1 } }, {})
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
  let Action = s:kind.action_table.argdelete
  call s:assert_exception(
  \   'No argument chosen',
  \   { -> Action({ 'word': 'bar', 'user_data': {} }, {}) }
  \ )
endfunction

function! s:test_action_open() abort
  argadd foo bar baz
  call assert_equal(3, argc())
  call assert_equal(['foo', 'bar', 'baz'], argv())

  let Action = s:kind.action_table.open

  try
    let candidate = {
    \  'word': 'foo',
    \  'user_data': { 'argument_index': 0 },
    \ }
    silent call assert_equal(0, Action(candidate, {}))
    call assert_equal('foo', bufname('%'))

    let candidate = {
    \  'word': 'bar',
    \  'user_data': { 'argument_index': 1 },
    \ }
    silent call assert_equal(0, Action(candidate, {}))
    call assert_equal('bar', bufname('%'))

    let candidate = {
    \  'word': 'baz',
    \  'user_data': { 'argument_index': 2 },
    \ }
    silent call assert_equal(0, Action(candidate, {}))
    call assert_equal('baz', bufname('%'))
  finally
    argdelete *
    silent bwipeout foo bar baz
  endtry
endfunction

function! s:test_action_open__with_invalid_index() abort
  argadd foo bar baz
  call assert_equal(3, argc())
  call assert_equal(['foo', 'bar', 'baz'], argv())

  let Action = s:kind.action_table.open

  try
    let candidate = {
    \  'word': 'foo',
    \  'user_data': { 'argument_index': 9 },
    \ }
    call s:assert_exception(':E16:', { -> Action(candidate, {}) })
  finally
    argdelete *
    silent bwipeout foo bar baz
  endtry
endfunction

function! s:test_action_open__within_modified_buffer() abort
  argadd foo bar baz
  call assert_equal(3, argc())
  call assert_equal(['foo', 'bar', 'baz'], argv())

  enew
  setlocal modified
  let bufnr = bufnr('%')

  let Action = s:kind.action_table.open

  try
    let candidate = {
    \  'word': 'foo',
    \  'user_data': { 'argument_index': 0 },
    \ }
    call s:assert_exception(':E37:', { -> Action(candidate, {}) })
  finally
    argdelete *
    silent bwipeout foo bar baz
    silent execute bufnr 'bwipeout!'
  endtry
endfunction

function! s:test_action_open_x() abort
  argadd foo bar baz
  call assert_equal(3, argc())
  call assert_equal(['foo', 'bar', 'baz'], argv())

  enew
  setlocal modified
  let bufnr = bufnr('%')

  let Action = s:kind.action_table['open!']

  try
    let candidate = {
    \  'word': 'foo',
    \  'user_data': { 'argument_index': 0 },
    \ }
    silent call Action(candidate, {})
    call assert_equal('foo', bufname('%'))

    let candidate = {
    \  'word': 'bar',
    \  'user_data': { 'argument_index': 1 },
    \ }
    silent call Action(candidate, {})
    call assert_equal('bar', bufname('%'))

    let candidate = {
    \  'word': 'baz',
    \  'user_data': { 'argument_index': 2 },
    \ }
    silent call Action(candidate, {})
    call assert_equal('baz', bufname('%'))
  finally
    argdelete *
    silent bwipeout foo bar baz
    silent execute bufnr 'bwipeout!'
  endtry
endfunction

function! s:test_kind_definition() abort
  call luis#_validate_kind(s:kind)
  call assert_equal('argument', s:kind.name)
endfunction

function! s:assert_exception(expected_message, callback)
  try
    silent call a:callback()
    call assert_true(0, 'Function must throw an exception')
  catch
    call assert_exception(a:expected_message)
  endtry
endfunction
