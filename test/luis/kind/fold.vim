let s:kind = g:luis#kind#fold#export

function! s:test_action_open() abort
  enew!
  setlocal foldmethod=marker
  call setline(1, [
  \   'foo { //{{{',
  \   '  bar { // {{{',
  \   '    baz;',
  \   '  } // }}}',
  \   '} // }}}',
  \ ])
  let bufnr = bufnr('%')

  call assert_equal(1, line('.'))
  call assert_equal(1, foldclosed(1))
  call assert_equal(1, foldclosed(2))

  try
    let _ = luis#do_action(s:kind, 'open', {
    \   'word': 'bar',
    \   'user_data': {
    \     'fold_lnum': 1,
    \   },
    \ })
    call assert_equal(0, _)
    call assert_equal(1, line('.'))
    call assert_equal(-1, foldclosed(1))
    call assert_equal(2, foldclosed(2))

    foldclose!

    let _ = luis#do_action(s:kind, 'open', {
    \   'word': 'bar',
    \   'user_data': {
    \     'fold_lnum': 2,
    \   },
    \ })
    call assert_equal(0, _)
    call assert_equal(2, line('.'))
    call assert_equal(-1, foldclosed(1))
    call assert_equal(-1, foldclosed(2))
  finally
    execute bufnr 'bwipeout!'
  endtry
endfunction

function! s:test_action_open_no_fold() abort
  let _ = luis#do_action(s:kind, 'open', {
  \   'word': '',
  \   'user_data': {},
  \ })
  call assert_equal('No fold chosen', _)
endfunction

function! s:test_kind_definition() abort
  call assert_equal('fold', s:kind.name)
  call assert_equal(type(s:kind.action_table), v:t_dict)
  call assert_equal(type(s:kind.key_table), v:t_dict)
  call assert_equal(s:kind.prototype, g:luis#kind#common#export)
endfunction
