let s:kind = g:luis#kind#register#export

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
    let _ = luis#internal#do_action(s:kind, action_name, {
    \   'word': '',
    \   'user_data': {},
    \ })
    call assert_equal('No register chosen', _)
  endfor
endfunction

function! s:test_action_delete() abort
  enew!
  let bufnr = bufnr('%')
  call setreg('a', 'foo', 'c')
  try
    let _ = luis#internal#do_action(s:kind, 'delete', {
    \   'word': 'foo',
    \   'user_data': {
    \     'register_name': 'a',
    \   },
    \ })
    call assert_equal('', getreg('a', 1))
    call assert_equal('', getregtype('a'))
  finally
    execute bufnr 'bwipeout!'
  endtry
endfunction

function! s:test_kind_definition() abort
  call assert_equal([], luis#internal#validate_kind(s:kind))
  call assert_equal('register', s:kind.name)
endfunction

function! s:do_test_put(expected_content, action_name, reg_key, reg_value, reg_type) abort
  enew!
  let bufnr = bufnr('%')
  call setreg(a:reg_key, a:reg_value, a:reg_type)
  try
    let _ = luis#internal#do_action(s:kind, a:action_name, {
    \   'word': 'bar',
    \   'user_data': {
    \     'register_name': a:reg_key,
    \   },
    \ })
    call assert_equal(a:expected_content, getline(1, line('$')))
  finally
    execute bufnr 'bwipeout!'
  endtry
endfunction
