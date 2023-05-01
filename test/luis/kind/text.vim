let s:kind = g:luis#kind#text#export

function! s:test_action_default() abort
  let reg_value = getreg('"')
  let reg_type = getregtype('"')
  let _ = luis#do_action(s:kind, 'default', {
  \   'word': 'foo',
  \ })
  call assert_equal('foo', getreg('"'))
  call assert_equal('v', getregtype('"'))
  call setreg('"', reg_value, reg_type)
endfunction

function! s:test_kind_definition() abort
  call assert_equal('text', s:kind.name)
  call assert_equal(type(s:kind.action_table), v:t_dict)
  call assert_equal(type(s:kind.key_table), v:t_dict)
  call assert_equal(s:kind.prototype, g:luis#kind#common#export)
endfunction
