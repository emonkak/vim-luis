let s:kind = luis#kind#register#import()

function! s:test_action_delete() abort
  enew
  let bufnr = bufnr('%')
  call setreg('a', 'foo', 'c')
  try
    let Action = s:kind.action_table.delete
    let candidate = {
    \   'word': 'foo',
    \   'user_data': {
    \     'register_name': 'a',
    \   },
    \ }
    silent call Action(candidate, {})
    call assert_equal('', getreg('a', 1))
    call assert_equal('', getregtype('a'))
  finally
    execute bufnr 'bwipeout!'
  endtry
endfunction

function! s:test_action_open() abort
  call s:do_test_put(['foo'], 'open', 'a', 'foo', 'c')
  call s:do_test_put(['', 'foo'], 'open', 'a', 'foo', 'l')
endfunction

function! s:test_action_open__with_no_register() abort
  let Action = s:kind.action_table.open
  let candidate = { 'word': '', 'user_data': {} }
  call s:assert_exception(
  \   'No register chosen',
  \   { -> Action(candidate, {}) }
  \ )
endfunction

function! s:test_action_open_x() abort
  call s:do_test_put(['foo'], 'open!', 'a', 'foo', 'c')
  call s:do_test_put(['foo', ''], 'open!', 'a', 'foo', 'l')
endfunction

function! s:test_kind_definition() abort
  call luis#_validate_kind(s:kind)
  call assert_equal('register', s:kind.name)
endfunction

function! s:assert_exception(expected_message, callback)
  try
    silent call a:callback()
    call assert_true(0, 'Function must throw an exception')
  catch
    call assert_exception(a:expected_message)
  endtry
endfunction

function! s:do_test_put(expected_content, action_name, reg_key, reg_value, reg_type) abort
  enew
  let bufnr = bufnr('%')
  call setreg(a:reg_key, a:reg_value, a:reg_type)
  try
    let Action = s:kind.action_table[a:action_name]
    let candidate = {
    \   'word': 'VIM',
    \   'user_data': {
    \     'register_name': a:reg_key,
    \   },
    \ }
    silent call Action(candidate, {})
    call assert_equal(a:expected_content, getline(1, line('$')))
  finally
    execute bufnr 'bwipeout!'
  endtry
endfunction
