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
    let _ = Action(candidate, {})
    call assert_equal(0, _)
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
  let _ = Action(candidate, {})
  call assert_equal('No mark chosen', _)
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
    let _ = Action(candidate, {})
    call assert_equal(0, _)
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
  let _ = Action(candidate, {})
  call assert_equal('No mark chosen', _)
endfunction

function! s:test_kind_definition() abort
  call assert_true(luis#_validate_kind(s:kind))
  call assert_equal('mark', s:kind.name)
endfunction
