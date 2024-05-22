let s:kind = luis#kind#mark#import()

function! s:test_action_delete() abort
  enew
  mark a
  let bufnr = bufnr('%')

  call assert_notequal('', execute('marks a', 'silent!'))

  try
    let Action = s:kind.action_table.delete
    let candidate = {
    \   'word': 'VIM',
    \   'user_data': {
    \     'mark_name': 'a',
    \   },
    \ }
    silent call Action(candidate, {})
    call assert_equal('', execute('marks a', 'silent!'))
  finally
    execute bufnr 'bwipeout!'
  endtry
endfunction

function! s:test_action_delete__no_mark() abort
  let Action = s:kind.action_table.delete
  let candidate = {
  \   'word': 'VIM',
  \   'user_data': {},
  \ }
  call s:assert_exception(
  \   'No mark chosen',
  \   { -> Action(candidate, {}) }
  \ )
endfunction

function! s:test_action_open() abort
  enew
  call setline(1, range(1, 10))
  5mark a
  let bufnr = bufnr('%')

  call assert_equal(1, line('.'))

  try
    let Action = s:kind.action_table.open
    let candidate = {
    \   'word': 'VIM',
    \   'user_data': {
    \     'mark_name': 'a',
    \   },
    \ }
    silent call Action(candidate, {})
    call assert_equal(5, line('.'))
  finally
    execute bufnr 'bwipeout!'
  endtry
endfunction

function! s:test_action_open__no_mark() abort
  let Action = s:kind.action_table.open
  let candidate = {
  \   'word': '',
  \   'user_data': {},
  \ }
  call s:assert_exception(
  \   'No mark chosen',
  \   { -> Action(candidate, {}) }
  \ )
endfunction

function! s:test_kind_definition() abort
  call luis#_validate_kind(s:kind)
  call assert_equal('mark', s:kind.name)
endfunction

function! s:assert_exception(expected_message, callback)
  try
    silent call a:callback()
    call assert_true(0, 'Function must throw an exception')
  catch
    call assert_exception(a:expected_message)
  endtry
endfunction
