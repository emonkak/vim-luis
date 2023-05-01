let s:kind = g:luis#kind#tag#export

function! s:test_action_open() abort
  call s:do_test_open(0, 'open', {})
  call s:do_test_open('Vim(tag):E37:', 'open', {
  \   '&bufhidden': 'unload',
  \   '&modified': 1,
  \ })
endfunction

function! s:test_action_open_invalid_tag() abort
  let _ = luis#do_action(s:kind, 'open', {
  \   'word': 'XXX',
  \ })
  call assert_match('Vim(tag):E\%(426\|433\):', _)
endfunction

function! s:test_action_open_x() abort
  call s:do_test_open(0, 'open!', {})
  call s:do_test_open(0, 'open!', {
  \   '&bufhidden': 'unload',
  \   '&modified': 1,
  \ })
endfunction

function! s:test_action_open_x_invalid_tag() abort
  let _ = luis#do_action(s:kind, 'open!', {
  \   'word': 'XXX',
  \ })
  call assert_match('Vim(tag):E\%(426\|433\):', _)
endfunction

function! s:test_kind_definition() abort
  call assert_equal('tag', s:kind.name)
  call assert_equal(type(s:kind.action_table), v:t_dict)
  call assert_equal(type(s:kind.key_table), v:t_dict)
  call assert_equal(s:kind.prototype, g:luis#kind#common#export)
endfunction

function! s:do_test_open(expected_result, action_name, buf_options) abort
  cd $VIMRUNTIME/doc

  silent edit `=tempname()`
  let bufnr = bufnr('%')
  for [key, value] in items(a:buf_options)
    call setbufvar(bufnr, key, value)
  endfor

  try
    silent let _ = luis#do_action(s:kind, a:action_name, {
    \   'word': 'vimtutor',
    \ })
    if type(a:expected_result) is v:t_string
      call assert_match(a:expected_result, _)
      call assert_equal(bufnr, bufnr('%'))
    else
      call assert_equal(0, _)
      call assert_notequal(bufnr, bufnr('%'))
      call assert_match('\*vimtutor\*', getline('.'))
      silent bwipeout
    endif
  finally
    silent execute bufnr 'bwipeout!'
    cd -
  endtry
endfunction
