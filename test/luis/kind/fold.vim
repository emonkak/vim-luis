let s:kind = luis#kind#fold#import()

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
    let Action = s:kind.action_table.open
    let candidate = {
    \   'word': 'bar',
    \   'user_data': { 'fold_lnum': 1 }
    \ }
    let _ = Action(candidate, {})
    call assert_equal(0, _)
    call assert_equal(1, line('.'))
    call assert_equal(-1, foldclosed(1))
    call assert_equal(2, foldclosed(2))

    foldclose!

    let Action = s:kind.action_table.open
    let candidate = {
    \   'word': 'bar',
    \   'user_data': { 'fold_lnum': 2 }
    \ }
    let _ = Action(candidate, {})
    call assert_equal(0, _)
    call assert_equal(2, line('.'))
    call assert_equal(-1, foldclosed(1))
    call assert_equal(-1, foldclosed(2))
  finally
    execute bufnr 'bwipeout!'
  endtry
endfunction

function! s:test_action_open__no_fold() abort
  let Action = s:kind.action_table.open
    let candidate = {
    \   'word': 'bar',
    \   'user_data': {}
    \ }
  let _ = Action(candidate, {})
  call assert_equal('No fold chosen', _)
endfunction

function! s:test_kind_definition() abort
  call assert_equal([], luis#_validate_kind(s:kind))
  call assert_equal('fold', s:kind.name)
endfunction
