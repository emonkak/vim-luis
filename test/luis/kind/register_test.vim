let s:kind = luis#kind#register#import()

function! s:test_action_Put() abort
  call s:do_test_put(['foo'], 'Put', 'a', 'foo', 'c')
  call s:do_test_put(['foo', ''], 'Put', 'a', 'foo', 'l')
endfunction

function! s:test_action_put() abort
  call s:do_test_put(['foo'], 'put', 'a', 'foo', 'c')
  call s:do_test_put(['foo'], 'default', 'a', 'foo', 'c')
  call s:do_test_put(['', 'foo'], 'put', 'a', 'foo', 'l')
  call s:do_test_put(['', 'foo'], 'default', 'a', 'foo', 'l')
endfunction

function! s:test_action_put__no_register() abort
  for action_name in ['put', 'default']
    let Action = s:kind.action_table[action_name]
    let _ = Action({ 'word': '', 'user_data': {} }, {})
    call assert_equal('No register chosen', _)
  endfor
endfunction

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
    let _ = Action(candidate, {})
    call assert_equal(0, _)
    call assert_equal('', getreg('a', 1))
    call assert_equal('', getregtype('a'))
  finally
    execute bufnr 'bwipeout!' 
  endtry
endfunction

function! s:test_kind_definition() abort
  call assert_true(luis#validate_kind(s:kind))
  call assert_equal('register', s:kind.name)
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
    silent let _ = Action(candidate, {})
    call assert_equal(0, _)
    call assert_equal(a:expected_content, getline(1, line('$')))
  finally
    execute bufnr 'bwipeout!' 
  endtry
endfunction
